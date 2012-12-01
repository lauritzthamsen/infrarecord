require 'sinatra'
require 'json'

class RailsLoader
  RAILS_ROOT = '~/Documents/HPI/ProgMod/rails-example'

  print "Loading Rails ..."
  require File.join(RAILS_ROOT, 'config', 'environment')
  puts " done"

  ActiveRecord::Base.establish_connection

  class AbortActiveRecordQuery < Exception; end

  #
  # Monkey patch Active Record
  #
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

  def execute_statement(statement)
    begin
      eval(statement)
    rescue AbortActiveRecordQuery => e
      p e.message
      output = e.message
    end
    output
  end

  private

  def self.load_rails(rails_root)
  end

  def self.patch_active_record
    puts "Patching Active Record"

  end
end

rails = RailsLoader.new

disable :protection

get '/:statement' do |statement|
  if /favicon/.match(statement) == nil
    rails.execute_statement(statement)
  end
end
