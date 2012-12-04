
require "uri"
require "net/http"
require "json"

import org.jruby.parser.Parser

module Redcar
  class InfraRecord
    class DocumentController
    
      attr_accessor :document, :server

      include Redcar::Document::Controller
      #include Redcar::Document::Controller::ModificationCallbacks
      include Redcar::Document::Controller::CursorCallbacks
    
      def initialize
        @current_line = ""
        @server = Redcar::InfraRecord::InfraRecordInterface.new
        @parser = Redcar::InfraRecord::SyntaxChecker.new
      end

      def cursor_moved(e)
        line = self.document.get_line(self.document.cursor_line)
        return if line == @current_line
        @current_line = line
        c = server.predict_orm_call_on_line(@current_line)
        puts c if c != nil
      end
      
      def eval_line(a_string)
        res = http_get("http://localhost:4567/#{@current_line}")
        puts res
      end
      
    end
  end
end
