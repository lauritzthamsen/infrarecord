require 'sinatra'
require 'json'
require './lib/repl_process.rb'

repl = ReplProcess.new

get '/:command' do |command|
  if /favicon/.match(command) == nil
    repl.eval(command)
  end
end