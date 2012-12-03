#require './parser.rb'

require "uri"
require "net/http"
require "json"

import org.jruby.parser.Parser

def http_get(url)
  url = URI.parse(url)
  req = Net::HTTP::Get.new(url.path)
  res = Net::HTTP.start(url.host, url.port) {|http|
    http.request(req)
  }
  return res.body
end

def http_post(url, data)
  return Net::HTTP.post_form(URI.parse(url), data).body
end
 
module Redcar
  class InfraRecord
    class DocumentController
      
      attr_accessor :document

      include Redcar::Document::Controller
      #include Redcar::Document::Controller::ModificationCallbacks
      include Redcar::Document::Controller::CursorCallbacks
    
      def initialize
        @current_line = ""
        @parser = Redcar::InfraRecord::SyntaxChecker.new
      end

      def cursor_moved(e)
        line = self.document.get_line(self.document.cursor_line)
        return if line == @current_line
        @current_line = line
        #puts "current line is " + @current_line
        node = @parser.check(@current_line)
        return if node == nil
        const_node = node.find_const_node
        if const_node == nil
          return
        end
        #print_possible_orm_call(const_node)
        predict_orm_call(@current_line)
      end
      
      def print_possible_orm_call(a_node)
        return if not (a_node.is_const_node? and 
          a_node.parent_node.is_call_node?)
        parent = a_node.parent_node
        name = parent.getName
        args = parent.getArgsNode
        puts "#{a_node.getName}.#{name}(#{args.to_s})"
      end

      def eval_line(a_string)
        res = http_get("http://localhost:4567/#{@current_line}")
        puts res
      end
      
      def predict_orm_call(a_string)
        params = {'statement' => a_string}
        res = http_post("http://localhost:4567/", params)
        res = JSON.parse(res)
        if res['status'] != 'not-found'
          puts res['query']
        end
      end

    end
  end
end
