
require 'erb'
require 'cgi'
require 'infrarecord/parser'
require 'infrarecord/infrarecord_interface'
require 'net/http'

module Redcar
  
  class Window
    
    def setIRNotebook(notebook)
      @notebook = notebook
    end
    
    def getIRNotebook
      @notebook
    end

    def setIRTab(tab)
      @tab = tab
    end

    def getIRTab
      @tab
    end
    
    def isInfraRecordRunning?
      @infraRecordRunning == true
    end
    
    def startInfraRecord
      @infraRecordRunning = true
      
      add_listener(:notebook_removed) do |notebook|
        if notebook == getIRNotebook
          setIRNotebook(nil)
        end
      end
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
      
      def createIRTabInNotebook(notebook)
        tab = notebook.new_tab(ConfigTab)
        tab.html_view.controller = Controller.new(win)
        
        win.setIRTab(tab)
        
        tab.add_listener(:close) do ||
          win.setIRTab(nil)
        end
        
        # focus necessary to trigger rendering...sucks...
        tab.focus
      end
      
      def createIRNotebook
        create_listener = win.add_listener(:new_notebook) do |notebook|
          createIRTabInNotebook(notebook)
          win.setIRNotebook(notebook)
        end
        win.create_notebook
        win.remove_listener(create_listener)
      end
      
      def execute
        return false if win.focussed_notebook_tab.nil?
        return false if win.focussed_notebook_tab.document.nil?
        
        if !win.isInfraRecordRunning?
          win.startInfraRecord
        end
                
        if win.getIRNotebook.nil?
          createIRNotebook
        elsif win.getIRTab.nil?
          createIRTabInNotebook(win.getIRNotebook)
        else
          win.getIRTab().controller_action('index', nil)
        end
      end
      
    end
    
    class Controller
      include HtmlController

      attr_accessor :ir_interface      

      def initialize(window)
        @window = window
        @ir_interface = Redcar::InfraRecord::InfraRecordInterface.new
        @current_line = ''
        @variables = {}
	@args = {}
      end
      
      def get_line
        document = @window.focussed_notebook_tab.document        
        document.get_line(document.cursor_line)
      end
      
      def title
        "InfraRecord"
      end
      
      def setBinding(name, value)
        @variables[name] = value
        puts @variables
      end
      
      def setArgValue(idx, value)
	@args[idx] = value
      end
      
      def resetArgs
	@args = {}
      end
    
      def index
	if get_line != @current_line
	  @current_line = get_line
	  resetArgs
	end
	variables_in_call = ir_interface.nonliteral_args_in_call(get_line)
	if variables_in_call == nil
	  '-----'
	elsif variables_in_call.empty?
	  orm_prediction = ir_interface.predict_orm_call_on_line(get_line)
	  p orm_prediction
	  if orm_prediction
	    p orm_prediction.keys
	    orm_prediction[:query] + "<br>(" + orm_prediction[:rows].count.to_s + " rows)"
	  else
	    '-----'
	  end
	else
	  '<script>' +
	  'sendBinding = function(name, value) {' +
	    'rubyCall("setBinding", name, value);' +
	  '}' +
	  'sendArgValue = function(index, value) {' +
	    'rubyCall("setArgValue", index, value);' +
	  '}' +
	  '</script>' +
	  '<form name="variables" >' + 
	  (variables_in_call.keys.reduce('') do |s, e|
	    name = variables_in_call[e]
	    s += name + ': <input type="text" onkeydown="Javascript: if (event.keyCode==13)' +
	    'sendBinding('+name+', event.target.value)"/><br />'
	  end) + '</form>'
	end
      end

    end

    def self.edit_view_gui_update(mate_text)
      if @text != mate_text.get_text_widget
        @text = mate_text.get_text_widget
        @text.add_key_listener(KeyListener.new)
        @text.addLineBackgroundListener(LineEventListener.new)
      end
    end
    
    class KeyListener
      def key_pressed(_); 
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
