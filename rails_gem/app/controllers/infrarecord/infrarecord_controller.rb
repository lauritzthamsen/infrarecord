module Infrarecord
  class InfrarecordController < ApplicationController
    def statement
      s = params[:statement]
      b = JSON.parse(params[:bindings] || '{}')
      p "Statement is '#{s}'"
      p "Bindings is '#{b}' (#{b.class})"

      orm_call = parser.first_possible_orm_call(s, b)
      if orm_call == nil
        render :status => 404, :text => { status: 'not-found' }.to_json
      else
        if sql = execute.get_sql(orm_call)
          rows = execute.get_query_result(sql)
          render :text => { status: 'sql', query: sql, rows: rows }.to_json
        else
          render :status => 404, :text => { status: 'not-found' }.to_json
        end
      end
    end

    private

    def parser
      @parser || ::Infrarecord::Parser.new
    end

    def execute
      @execute || ::Infrarecord::Execute.new
    end
  end
end
