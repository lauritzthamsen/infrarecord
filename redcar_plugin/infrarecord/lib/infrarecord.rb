
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
        @ir_interface = Redcar::InfraRecord::InfraRecordInterface.new(self)
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
      
      def scrollDocumentToLine(lineNumber)
        document.scroll_to_line(lineNumber + 1)
      end

      def index
        output = '<div id="ormcordion">' + "\n"
        panel_count = -1;
        active_panel_index = -1;

        (0..document.line_count).each do |line_number|
          resetArgs

          statement = get_line(line_number)
          statement_line_number = (line_number + 1)
          variables_in_call = ir_interface.nonliteral_args_in_call(line_number)

          css_class = if statement_line_number == current_line_number
            "current"
          end

          # no call nodes found
          next if variables_in_call.nil?

          panel_count += 1
          if statement_line_number == current_line_number
            active_panel_index = panel_count
          end

          output += "<h3 class=\"#{css_class}\">Line #{statement_line_number.to_s}</h3>\n"
          output += "<div class=\"statement\" id=\"line#{statement_line_number.to_s}\">"

          # get context
          context = []
          i = line_number - 1
          while i >= 0 && get_line(i).match(/^\s*#IR\s*(.*)/)
            context << $1
            i -= 1
          end

          if orm_prediction = ir_interface.predict_orm_call_on_line(line_number, context.join("; "))
            p orm_prediction[:rows]
            output += """
                #{orm_prediction[:query]}<br>
                (#{orm_prediction[:rows].count.to_s} rows)
            """
          end
          output += "</div>\n"
          
        end
        output += "</div>\n"
        output += "<script>$('#ormcordion').maccordion({collapsible: true, active: #{active_panel_index}});</script>\n"
        output += "<script>$('#ormcordion').bind('maccordionactivate', function(event, data) {rubyCall('scrollDocumentToLine', parseInt(data.toggled.text().substring('Line '.length)))});</script>"
        puts output
        output
        
        

        rhtml = ERB.new(File.read(File.join(File.dirname(__FILE__), "..", "views", "index.html.erb")))
        rhtml.result(binding)
      end

    end

    def self.edit_view_gui_update(mate_text)
      if @text != mate_text.get_text_widget
        @text = mate_text.get_text_widget
        @text.add_key_listener(KeyListener.new)
        @text.add_mouse_listener(MouseListener.new)
        @text.addLineBackgroundListener(LineEventListener.new)
      end
    end

    class KeyListener
      def initialize
        @cached_line = ""
      end

      def key_pressed(_);
      end

      def key_released(e);
        doc = Redcar.app.focussed_window.focussed_notebook_tab.document
        line = doc.get_line(doc.cursor_line)
        return if @cached_line == line
        if Redcar.app.focussed_window.isInfraRecordRunning?
          InfraRecordCommand.new.execute
        end
        @cached_line = line
      end
    end

    class MouseListener
      def mouseDown(_)
      end

      def mouseUp(_)
        if Redcar.app.focussed_window.isInfraRecordRunning?
          InfraRecordCommand.new.execute
        end
      end

      def mouseDoubleClick(_)
      end
    end

    class LineEventListener
      def lineGetBackground(_); end
    end

  end

end
