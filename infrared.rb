require 'sinatra'

require_relative './lib/rails_loader.rb'

rails = RailsLoader.new

configure do
  disable :protection
end

get '/:statement' do |statement|
  halt [ 404 ] if /favicon/.match(statement)

  if sql = rails.get_sql(statement)
    [ 200, {}, { status: 'sql', query: sql }.to_json ]
  else
    [ 404, {}, { status: 'not-found' }.to_json ]
  end
end
