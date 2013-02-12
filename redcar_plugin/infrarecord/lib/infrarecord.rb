
require 'erb'
require 'cgi'
require 'infrarecord/parser'
require 'infrarecord/infrarecord_interface'
require 'net/http'

module Redcar
  
  class Document
    
    @suppress_highlighting = false
    
    attr_accessor :suppress_highlighting
    
  end

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

      
      def scrollDocumentToLine(lineNumber)
        return unless document
        document.scroll_to_line(lineNumber + 1)
        # FIXME find a way to suppress highlighting
        #   this is obviously a problem since the javascript may be
        #   executed asynchronously. simply setting a flag is not enough.
        #if (!document.suppress_highlighting) 
        #  document.set_selection_range(
        #      document.offset_at_line(lineNumber - 1),
        #      document.offset_at_line_end(lineNumber - 1))
        #end
      end

      def render_orm_prediction_html(line_number)
        output = ""
        statement = get_line(line_number)
        statement_line_number = (line_number + 1)
        return nil unless ir_interface.has_potential_orm_call?(line_number)

        css_class = if statement_line_number == current_line_number
          "current"
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
        output
      end
      
      def index
        output = '<div id="ormcordion">' + "\n"
        panel_count = -1;
        active_panel_index = -1;

        (0..document.line_count).each do |line_number|
          statement_line_number = (line_number + 1)
          prediction_html = render_orm_prediction_html(line_number)
          if (prediction_html)
            panel_count += 1
            if statement_line_number == current_line_number
              active_panel_index = panel_count
            end
            output += prediction_html
          end
        
        end
        output += "</div>\n"
        output += "<script>$('#ormcordion').maccordion({collapsible: true, active: #{active_panel_index}});</script>\n"
        output += "<script>$('#ormcordion').bind('maccordionactivate', function(event, data) {rubyCall('scrollDocumentToLine', parseInt(data.toggled.text().substring('Line '.length)))});</script>"
        
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
        doc.suppress_highlighting = true
        line = doc.get_line(doc.cursor_line)
        return if @cached_line == line
        if Redcar.app.focussed_window.isInfraRecordRunning?
          InfraRecordCommand.new.execute
        end
        @cached_line = line
        doc.suppress_highlighting = false
      end
    end

    class MouseListener
      def mouseDown(_)
      end

      def mouseUp(_)
        doc = Redcar.app.focussed_window.focussed_notebook_tab.document
        doc.suppress_highlighting = true
        if Redcar.app.focussed_window.isInfraRecordRunning?
          InfraRecordCommand.new.execute
        end
        doc.suppress_highlighting = false
      end

      def mouseDoubleClick(_)
      end
    end

    class LineEventListener
      def lineGetBackground(_); end
    end

  end

end
