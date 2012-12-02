require 'ruby_parser'

module InfraRecord
  
  class Parser
    
    def initialize
      @parser = Ruby19Parser.new
    end
    
    def parse(a_string)
      sexp = @parser.parse(a_string)
      AstNode.new(sexp, nil)
    end
    
    def find_possible_orm_calls(a_string)
      sexp = self.parse(a_string)
      #sexp.find_const_nodes.reduce("") { |s, e| s + e + " "}
      sexp
    end
    
  end
  
  #FIXME entries works different than child_nodes in JRuby parser. Sorry i f'ed this up
  
  class AstNode
    attr_accessor :sexp, :parent_node, :is_literal
      
    def initialize(sexp, parent)
      @sexp = sexp
      @parent_node = parent
      if sexp.class != Sexp
        @is_literal = true
      else
        @is_literal = false
      end
    end
    
    def node_type
      if self.is_literal
        :literal
      else
        super
      end
    end
    
    def is_const_node?
      node_type == :const
    end
      
    def is_call_node?
      node_type == :call
    end
      
    #here be more stuff
      
    def child_nodes
      if self.is_literal
        res = []
      else
        res = @sexp.entries.map { |e| AstNode.new(e, self)}
      end
      res
    end
      
    def all_child_nodes
      res = [self]
      self.child_nodes.each { |e|
        res = res.concat(e.all_child_nodes)
      }
      res
    end
      
    def find_const_nodes
      all_child_nodes.collect { |e|
        e.is_const_node?
      }
    end
      
    def method_missing(name, *args, &block)
      @sexp.send(name, *args, &block)
    end
      
  end
  
end
