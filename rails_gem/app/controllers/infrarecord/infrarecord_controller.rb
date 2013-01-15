module Infrarecord
  class InfrarecordController < ApplicationController
    def statement
      s = params[:statement]
      b = JSON.parse(params[:bindings] || '{}')
      p "Statement is '#{s}'"
      p "Bindings is '#{b}' (#{b.class})"

      orm_call = parser.first_possible_orm_call(s, b)
      p orm_call
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

    def models
      res = ActiveRecord::Base.subclasses.map {|e| e.to_s}
      render :text => { models:  res }.to_json
      #render :text => "Hello World"
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
