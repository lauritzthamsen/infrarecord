
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
      
      def document
        @window.focussed_notebook_tab.document   
      end
      
      def current_line_number
        document.cursor_line + 1
      end
      
      def get_line(line_number=nil)
        line_number = document.cursor_line unless line_number
        document.get_line(line_number)
      end
            
      def title
        "InfraRecord"
      end
      
      def setBinding(name, value)
        @variables[name] = value
        p @variables
      end
      
      def getBinding(name)
	      @variables[name].to_s
      end
      
      def setArgValue(idx, value)
	      @args[idx] = value
	      p @args
      end
      
      def update_args_from_bindings(variables_map)
	      variables_map.keys.each do |idx|
	        name = variables_map[idx]
	        setArgValue(idx, getBinding(name))
	      end
      end
      
      def resetArgs
	      @args = {}
      end
    
      def index
        output = """
          <script>          
            sendBinding = function(name, value) {
              rubyCall('setBinding', name, value);
            };
            sendArgValue = function(index, value) {
              rubyCall('setArgValue', index, value);
            };
          </script>
        """
        
        (0..document.line_count).each do |line_number|
          resetArgs
          
          statement = get_line(line_number)
          statement_line_number = (line_number + 1)
  	      variables_in_call = ir_interface.nonliteral_args_in_call(statement)
          
          style = if statement_line_number == current_line_number
              "border : 1px solid black"
            end
          
          if variables_in_call.nil?
            # no call nodes found
            next
          elsif variables_in_call.empty?
            # no variables to be entered by user
            if orm_prediction = ir_interface.predict_orm_call_on_line(statement)
              output += """
                <div style=\"#{style}\" id='#{statement_line_number.to_s}'>
                  ##{statement_line_number.to_s}<br>
                  #{orm_prediction[:query]}<br>
                  (#{orm_prediction[:rows].count.to_s} rows)
                </div>
              """
            end
          else
            # variables to be entered by user
            update_args_from_bindings(variables_in_call)
            i = 0
            output += "<form name='variables'>"
            output += variables_in_call.keys.reduce('') do |string, key|
              name = variables_in_call[key]
              id = i.to_s
              i += 1
              
              string += """
                <label>#{name}:<name>
                <input 
                  type=\"text\"
                  id=\"#{id}\"
                  value=\"#{getBinding(name)}\"
                  onkeyup=\" 
                    sendBinding('#{name}', event.target.value);
                    sendArgValue('#{id}', event.target.value);
                  \"
                /><br />
              """
            end
            output += '</form>'
          end
          output += "<br><br>"
        end
        
	      output
        
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
