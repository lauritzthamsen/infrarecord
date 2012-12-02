

def http_get(url)
  url = URI.parse(url)
  req = Net::HTTP::Get.new(url.path)
  res = Net::HTTP.start(url.host, url.port) {|http|
    http.request(req)
  }
  return res.body
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
      end

      def cursor_moved(e)
        line = self.document.get_line(self.document.cursor_line)
        return if line == @current_line
        @current_line = line
        puts "current line is " + @current_line
        eval_line(@current_line)
      end

      def eval_line(a_string)
        res = http_get("http://localhost:4567/#{@current_line}")
        puts res
      end

    end
  end
end
