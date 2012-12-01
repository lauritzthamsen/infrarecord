
require 'erb'
require 'cgi'

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
        controller = Controller.new
        
        # i'm awefully sorry for this
        win.create_notebook
        win.set_focussed_notebook(win.nonfocussed_notebook)
        tab = win.new_tab(ConfigTab)
        tab.html_view.controller = controller
        tab.focus
      end
    end
    
    class Controller
      include HtmlController
      
      def title
        "InfraRecord"
      end
    
      def index
        rhtml = ERB.new(File.read(File.join(File.dirname(__FILE__), "..", "views", "index.html.erb")))
        rhtml.result(binding)
      end
    end
  end
    
end