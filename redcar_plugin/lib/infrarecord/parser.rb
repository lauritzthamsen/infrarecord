require 'java'

import org.jruby.parser.Parser
import org.jruby.parser.ParserConfiguration
import org.jruby.CompatVersion

module Redcar
  class InfraRecord
    class SyntaxChecker < Redcar::SyntaxCheck::Checker
      supported_grammars "Ruby", "Ruby on Rails", "RSpec"

      def initialize
      end

      def check(line)
        file = "local buffer"
        begin
          parser.parse(file, line.to_java.get_bytes, config_19.scope, config_19)
        rescue SyntaxError => e
          #create_syntax_error(file, e.exception.message, file).annotate
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
