module Infrarecord
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
end
