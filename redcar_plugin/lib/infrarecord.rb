
require 'erb'
require 'cgi'
require 'infrarecord/document_controller'

module Redcar
  class InfraRecord
    
    def self.menus
      Menu::Builder.build do
        sub_menu "Debug", :priority => 22 do
          group(:priority => 6) do
            item "InfraRecord", InfraRecord::OpenCommand
            separator
          end
        end
      end
    end

    
    class OpenCommand < Redcar::Command
      
      def execute
        return false if win.focussed_notebook_tab.nil?
        return false if win.focussed_notebook_tab.document.nil?
                  
        current_document = win.focussed_notebook_tab.document
        @current_line = current_document.cursor_line + 1
              
        # create_notebook does not return the new notebook
        listener = win.add_listener(:new_notebook, &method(:open_infrarecord_in_notebook))
        win.create_notebook
        win.remove_listener(listener)
      end
      
      def open_infrarecord_in_notebook(notebook)
        controller = Controller.new(@current_line)
        win.set_focussed_notebook(notebook)
        tab = win.new_tab(ConfigTab)
        tab.html_view.controller = controller
        tab.focus
        
        # how to close the notebook that present our infrarecord view in a tab??
        # tab.add_listener(:close, )
      end
      
    end
    
    class Controller
      include HtmlController
      
      def initialize(line_number)
        @line_number = line_number
      end
      
      def title
        "InfraRecord"
      end
    
      def index
        rhtml = ERB.new(File.read(File.join(File.dirname(__FILE__), "..", "views", "index.html.erb")))
        rhtml.result(binding)
      end

    end

    def self.edit_view_gui_update(mate_text)
      if @text != mate_text.get_text_widget
        @text = mate_text.get_text_widget
        @text.add_key_listener(KeyListener.new)
        @text.addLineBackgroundListener(LineEventListener.new)
      end
    end

    def self.document_cursor_listener
      puts "DOCUMENT_CUROR"
      @doc = DocumentController.new
    end
        
    class KeyListener
      def key_pressed(_); 
         puts "Infrarecord: Key pressed"
      end
      def key_released(e); 
        if e.stateMask == Swt::SWT::CTRL
          case e.keyCode
            when 100 # 'd'
              puts "this could be a do-it"
              #puts 'doit' + e.widget.selection_line
          end
        end
      end
    end  
    
    class LineEventListener
      def lineGetBackground(_); end
    end

  end
    
end