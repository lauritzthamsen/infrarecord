
module Redcar
  class InfraRecord
    class DocumentController

      attr_accessor :document

      include Redcar::Document::Controller
      #include Redcar::Document::Controller::ModificationCallbacks
      include Redcar::Document::Controller::CursorCallbacks
    
      def cursor_moved(e)
        current_line = self.document.cursor_line
        puts "current line is " + 
          self.document.get_line(current_line)
      end

    end
  end
end
