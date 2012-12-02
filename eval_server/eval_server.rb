require 'sinatra'
require 'json'

get '/:statement' do |statement|
  halt [ 404 ] if /favicon/.match(statement)

  [ 200, {}, { status: 'eval', query: nil, result: eval(statement) }.to_json ]
end

