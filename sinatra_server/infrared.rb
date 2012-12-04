require 'sinatra'
require 'json'
require 'ruby2ruby'

require_relative './lib/rails_loader.rb'
require_relative './lib/parser.rb'

# Have you ever seen such a global parser? Yuk!
$parser = InfraRecord::Parser.new

def rails
  @rails ||= RailsLoader.new
end
rails

configure do
  disable :protection
end

def handle_statement(statement)
  halt [ 404 ] if /favicon/.match(statement)

  STDOUT << "statement is '#{statement}'\n"

  orm_call = $parser.first_possible_orm_call(statement)
  if orm_call == nil
    return [ 404, {}, { status: 'not-found' }.to_json ]
  end
  
  if sql = rails.get_sql(orm_call)
    [ 200, {}, { status: 'sql', query: sql }.to_json ]
  else
    [ 404, {}, { status: 'not-found' }.to_json ]
  end
end

get '/:statement' do |statement|
  handle_statement(statement)
end

post '/' do
  handle_statement(params[:statement])
end


get '/ast/:statement' do |statement|
  #ast = InfraRecord::Parser.new.parse(statement)
  #Ruby2Ruby.new.process(ast)
  res = $parser.find_possible_orm_calls(statement)
  #res = parser.parse(statement).all_child_nodes
  [200, {}, res.to_json ]
end
