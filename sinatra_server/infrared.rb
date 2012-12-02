require 'sinatra'
require 'json'

require_relative './lib/rails_loader.rb'
require_relative './lib/parser.rb'

def rails
  @rails ||= RailsLoader.new
end
rails

configure do
  disable :protection
end

def handle_statement(statement)
  halt [ 404 ] if /favicon/.match(statement)

  if sql = rails.get_sql(statement)
    [ 200, {}, { status: 'sql', query: sql }.to_json ]
  else
    [ 404, {}, { status: 'not-found' }.to_json ]
  end
end

get '/models' do
  rails.model_names.to_json
end

get '/:statement' do |statement|
  handle_statement(statement)
end

post '/' do
  handle_statement(params[:statement])
end

get '/ast/:statement' do |statement|
  InfraRecord::Parser.new.parse(statement)
end