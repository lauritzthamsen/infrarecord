module Infrarecord
  class Execute
    def get_sql(statement)
      execute_model_query(statement)
    end

    def get_query_result(sql_statement)
      ActiveRecord::Base.connection.old_execute(sql_statement)
    end

    private

    def execute_model_query(statement)
      output = nil

      begin
        ActiveRecord::Base.connection.prepare_infrarecord_call
        eval(statement)
      rescue AbortActiveRecordQuery => e
        p "INTERCEPTED QUERY: #{e.message}"
        output = e.message
      rescue => e
        p "EXCEPTION: #{e.message}"
      ensure
        ActiveRecord::Base.connection.finish_infrarecord_call
      end
      output
    end
  end
end
