class RailsLoader
  RAILS_ROOT = '../../rails_example'

  #
  # Load Rails app
  #
  print "Loading Rails ..."
  require_relative File.join(RAILS_ROOT, 'config', 'environment')
  puts " done"

  #
  # Monkey patch Active Record
  #

  # We need to establish a connection, so the Adapters can be monkey patched
  ActiveRecord::Base.establish_connection

  class AbortActiveRecordQuery < Exception; end

  ActiveRecord::ConnectionAdapters::Mysql2Adapter.class_eval do
    # These queries will not be executed
    QUERY_BLACKLIST = %w{ SELECT UPDATE DELETE INSERT ALTER }

    alias_method :old_execute, :execute
    def execute(sql, name = nil)
      if QUERY_BLACKLIST.map { |q| !!(sql.match q) }.any?
        raise AbortActiveRecordQuery, sql
      else
        old_execute(sql, name)
      end
    end
  end

  #
  # done Monkey Patching
  #

  def get_sql(statement)
    if has_model?(statement)
      execute_model_query(statement)
    else
      nil
    end
  end

  private

  def execute_model_query(statement)
    output = nil

    begin
      eval(statement)
    rescue AbortActiveRecordQuery => e
      p "INTERCEPTED QUERY: #{e.message}"
      output = e.message
    rescue => e
      p "EXCEPTION: #{e.message}"
    end

    output
  end

  def has_model?(statement)
    model_names.map { |m| !!(statement.match /#{m}\./) }.any?
  end

  def models
    @models ||= begin
      Rails.application.eager_load!
      ActiveRecord::Base.descendants
    end
  end

  def model_names
    models.map(&:name)
  end
end
