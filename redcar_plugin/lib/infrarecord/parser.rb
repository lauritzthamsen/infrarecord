require 'java'


import org.jruby.parser.Parser
import org.jruby.parser.ParserConfiguration
import org.jruby.CompatVersion

module Redcar
  class InfraRecord
    
    class Node
      attr_accessor :raw_node, :parent_node
      
      def initialize(jruby_node, parent)
        @raw_node = jruby_node
        @parent_node = parent
      end
      
      def node_type_string
        @raw_node.getNodeType.to_s
      end
        
      def is_const_node?
        node_type_string == "CONSTNODE"
      end
      
      def is_call_node?
        node_type_string == "CALLNODE"
      end
      
      #here be more stuff
      
      def child_nodes
        @raw_node.childNodes.map{ |e| Node.new(e, self)}
      end
      
      def all_child_nodes
        res = [self]
        self.child_nodes.each{ |e|
          res = res.concat(e.all_child_nodes)
        }
        res
      end
      
      def find_const_node
        all_child_nodes.detect { |e|
          e.is_const_node?
        }
      end
      
      def method_missing(name, *args, &block)
        @raw_node.send(name, *args, &block)
      end
      
    end
    
    class SyntaxChecker < Redcar::SyntaxCheck::Checker
      supported_grammars "Ruby", "Ruby on Rails", "RSpec"

      def initialize
      end

      def check(line)
        file = "local buffer"
        begin
          n = parser.parse(file, line.to_java.get_bytes, config_19.scope, config_19)
          return Node.new(n.getBodyNode, nil)
        rescue SyntaxError => e
          #create_syntax_error(file, e.exception.message, file).annotate
          nil
        end 
      end 

      def create_syntax_error(doc, message, file)
        message  =~ /#{Regexp.escape(file)}:(\d+):(.*)/
        line     = $1.to_i - 1 
        message  = $2
        Redcar::SyntaxCheck::Error.new(doc, line, message)
      end 

      private

      def runtime
        org.jruby.Ruby.global_runtime
      end 

      def parser
        @parser ||= Parser.new(runtime)
      end 

      def config_19
        @config_19 ||= ParserConfiguration.new(runtime, 0, false, CompatVersion::RUBY1_9)
      end

      def config_18
        @config_18 ||= ParserConfiguration.new(runtime, 0, false, CompatVersion::RUBY1_8)
      end
    end
  end
end
