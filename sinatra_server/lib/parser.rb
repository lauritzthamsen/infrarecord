require 'ruby_parser'

module InfraRecord
  
  class Parser
    
    def initialize
      @parser = Ruby19Parser.new
    end
    
    def parse (a_string)
      sexp = @parser.parse(a_string)
      AstNode.new(sexp, nil)
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
      @sexp.entries.map { |e| AstNode.new(e, self)}
    end
      
    def all_child_nodes
      res = [self]
      self.child_nodes.each { |e|
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
      @sexp.send(name, *args, &block)
    end
      
  end
  
end
