
require 'erb'
require 'cgi'
require 'infrarecord/parser'
require 'infrarecord/document_controller'
require 'infrarecord/infrarecord_interface'
require 'net/http'

module Redcar
  
  class Window
    
    def setIRNotebook(notebook)
      @notebook = notebook
    end
    
    def getIRNotebook()
      @notebook
    end

    def setIRTab(tab)
      @tab = tab
    end

    def getIRTab()
      @tab
    end
    
    def isInfraRecordRunning?
      !(getIRNotebook.nil? && getIRTab.nil?)
    end
    
  end
  
  class InfraRecord
    
    def self.menus
      Menu::Builder.build do
        sub_menu "Debug", :priority => 22 do
          group(:priority => 0) do
            item "InfraRecord", InfraRecord::InfraRecordCommand
            separator
          end
        end
      end
    end
        
    class InfraRecordCommand < Redcar::Command
      
      def initialize
        @win = Redcar.app.focussed_window
      end
      
      def execute
        return false if win.focussed_notebook_tab.nil?
        return false if win.focussed_notebook_tab.document.nil?
                
        if !win.isInfraRecordRunning?
          win.add_listener(:new_notebook) do |notebook|
            tab = notebook.new_tab(ConfigTab)
            tab.html_view.controller = Controller.new(win)
            # fixme: focus is necessary for HTML rendering. but why, oh why?
            tab.focus
            win.setIRTab(tab)
            win.setIRNotebook(notebook)
          end
          win.create_notebook
        else
          win.getIRTab().controller_action('index', nil)
        end
      end
      
    end
    
    class Controller
      include HtmlController
      
      def initialize(window)
        @window = window
      end
      
      def get_line
        document = @window.focussed_notebook_tab.document        
        document.get_line(document.cursor_line)
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
      puts "Creating new DocumentController"
      @doc = DocumentController.new
    end
        
    class KeyListener
      def key_pressed(_); 
        #puts "Infrarecord: Key pressed"
      end
      def key_released(e); 
              
        if Redcar.app.focussed_window.isInfraRecordRunning?
          InfraRecordCommand.new.execute
        end
        
        if e.stateMask == Swt::SWT::CTRL
          case e.keyCode
            when 100 # 'd'
              puts "do stuff"
          end
        end
      end
    end  
    
    class LineEventListener
      def lineGetBackground(_); end
    end

  end
    
end
