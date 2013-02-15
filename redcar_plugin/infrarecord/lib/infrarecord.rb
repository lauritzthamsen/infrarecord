
require 'erb'
require 'cgi'
require 'infrarecord/parser'
require 'infrarecord/infrarecord_interface'
require 'net/http'
require 'json'

module Redcar

  class Document

    def present_line(line_number)
      scroll_to_line(line_number + 1)
      set_selection_range(
         offset_at_line(line_number - 1),
         offset_at_line_end(line_number - 1))
    end

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

    def ensureHTML
      if !@HTMLinitialized && self.getIRTab
        self.getIRTab.controller_action("index", nil)

        @HTMLinitialized = true
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

        # focus necessary to trigger rendering
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

        win.ensureHTML

        if win.getIRNotebook.nil?
          createIRNotebook
        elsif win.getIRTab.nil?
          createIRTabInNotebook(win.getIRNotebook)
        else
          win.getIRTab.html_view.controller.update
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

      def present_line_in_document(lineNumber)
        return unless document
        document.present_line(lineNumber)
      end

      def render_orm_prediction_html(line_number)

        statement = get_line(line_number)
        statement_line_number = (line_number + 1)
        return nil unless ir_interface.has_potential_orm_call?(line_number)

        context = []
        i = line_number - 1
        while i >= 0 && get_line(i).match(/^\s*#IR\s*(.*)/)
          context << $1
          i -= 1
        end

        orm_prediction = ir_interface.predict_orm_call_on_line(line_number, context.join("; "))

        return "" if not orm_prediction

        css_class = if statement_line_number == current_line_number
          "current"
        end
        output = ""
        output += "<h3 class=\"#{css_class}\">Line #{statement_line_number.to_s}: #{orm_prediction[:model]}</h3>\n"
        output += "<div class=\"statement\" id=\"line#{statement_line_number.to_s}\">"
        output += """
          #{orm_prediction[:query]}<br>
          (#{orm_prediction[:rows].count.to_s} rows)<br>
          """
        output += render_table(orm_prediction[:column_names], orm_prediction[:rows])
        output += "</div>\n"
        output
      end

      def index
        rhtml = ERB.new(File.read(File.join(File.dirname(__FILE__), "..", "views", "index.html.erb")))
        rhtml.result(binding)
      end

      def get_orm_predictions
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

      end

      def update
        self.execute(update_js)
      end

      def update_js
        column_names = [ "a", "b", "d"].to_json.gsub('"', %q(\\\"))
        rows = [ [ 1, 2, 3 ], [1,2,3] ].to_json.gsub('"', %q(\\\"))

        js = ERB.new(File.read(File.join(File.dirname(__FILE__), "..", "views", "update.js.erb")))
        js.result(binding)
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
        doc = Redcar.app.focussed_window.focussed_notebook_tab.document
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
