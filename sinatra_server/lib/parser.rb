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
      #FIXME check if parent is call node, then figure out the chain etc.
      sexp.find_const_nodes
    end
    
  end
    
  class AstNode
    attr_accessor :sexp, :parent_node
      
    def initialize(sexp, parent)
      @sexp = sexp
      @parent_node = parent
    end
    
    def is_const_node?
      node_type == :const
    end
      
    def is_call_node?
      node_type == :call
    end
      
    #here be more stuff
      
    def child_nodes
      @sexp.entries.select{ |e| e.class == Sexp }.map{ |e| AstNode.new(e, self) }
    end
      
    def all_child_nodes
      res = [self]
      self.child_nodes.each { |e|
        res = res.concat(e.all_child_nodes)
      }
      res
    end
      
    def find_const_nodes
      all_child_nodes.select { |e|
        e.is_const_node?
      }
    end
      
    def method_missing(name, *args, &block)
      @sexp.send(name, *args, &block)
    end
      
  end
  
end
