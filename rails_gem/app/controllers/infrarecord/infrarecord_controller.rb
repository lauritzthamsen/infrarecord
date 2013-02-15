require 'ruby2ruby'

module Infrarecord
  class InfrarecordController < ApplicationController
    def statement
      s = params[:statement]
      c = (params[:context] || '')
      p "Statement is '#{s}'"
      p "Context is '#{c}'"

      orm_call = parser.first_possible_orm_call(s, {})
      p orm_call
      if orm_call == nil
        render :status => 404, :text => { status: 'not-found' }.to_json
      else
        innermost_receiver = parser.parse(orm_call).innermost_receiver_name
        column_names = nil
        column_names = eval(innermost_receiver).column_names if innermost_receiver
        if sql = execute.get_sql(call_with_context(orm_call, c))
          rows = execute.get_query_result(sql)
          render :text => { status: 'sql', query: sql, 
                            rows: rows,
                            possible_call: orm_call,
                            model: innermost_receiver.to_s,
                            column_names: column_names}.to_json
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

    def call_with_context(orm_call, context)
      "#{context}; #{orm_call}"
    end
  end
end
