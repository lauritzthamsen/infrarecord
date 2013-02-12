module Infrarecord
  ActiveRecord::Base.establish_connection

  class AbortActiveRecordQuery < Exception; end

  ActiveRecord::ConnectionAdapters::Mysql2Adapter.class_eval do
    # These queries will not be executed
    QUERY_BLACKLIST = %w{ SELECT UPDATE DELETE INSERT ALTER }

    @expects_infrarecord_call = false
    
    def prepare_infrarecord_call
      @expects_infrarecord_call = true
    end
    
    def finish_infrarecord_call
      @expects_infrarecord_call = false
    end
    
    alias_method :old_execute, :execute
    def execute(sql, name = nil)
      if @expects_infrarecord_call
        if QUERY_BLACKLIST.map { |q| !!(sql.match q) }.any?
          raise AbortActiveRecordQuery, sql
        end
      end
      old_execute(sql, name)   
    end
  end
end
