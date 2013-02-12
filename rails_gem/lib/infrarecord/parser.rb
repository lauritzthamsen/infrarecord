require 'ruby2ruby'
require 'ruby_parser'

class Sexp

  #extensions to Sexp

  def is_call?
    count > 2 and self[0] == :call
  end

  def has_receiver?
    is_call? and self[1] != nil
  end

  def has_const_receiver?
    has_receiver? and self[1] and self[1][0] == :const
  end

  def recursive_replace(old, new)
    if self == old
      return new
    end
    res = Sexp.new
    self.each do |exp|
      if exp.class == Sexp
        res << exp.recursive_replace(old, new)
      else
        res << exp
      end
    end
    res
  end

  def args
    return nil if not is_call?
    return [] if self.count < 4
    self[3..self.count]
  end

  def method_name
    return nil if not is_call?
    return self[2].to_s
  end
  
  def receiver_node
    # in:  s(:call, s(:const, :Post), :all))
    # out: s(:const, :Post)
    return nil if not has_receiver?
    return self[1]
  end
  
  def innermost_receiver_node
    # in:  s(:call, s(:call, s(:const, :Post), :all), :empty?)
    # out: s(:const, :Post)
    return self if not is_call?
    receiver = receiver_node
    if receiver.is_call?
      return receiver.innermost_receiver_node
    else 
      return receiver
    end
  end
  
  def innermost_receiver_name
    node = innermost_receiver_node
    return "" if node.nil?
    return node[1].to_s if node[1]
    return ""
  end

  def replace_arg_in_const_call(idx, new_exp)
    res = self.clone
    return res if not has_const_receiver?
    return res if args.count < 1
    res[3 + idx] = Sexp.from_array(new_exp)
    res
  end

  def replace_args_with_bindings(bindings)
    res = self.clone
    return res if not has_const_receiver?
    parser = RubyParser.new
    bindings.each do |k, v|
      # all vs must be Hashes with 'value' key
      # calling parser.parse
      #   v['value']       | parser.parse(v)
      #--------------------+------------------
      # "5"                | s(:lit, 5)
      # "\"foo\""          | s(:str, "foo")
      #
      # All values in bindings are expected to be strings
      res = res.replace_arg_in_const_call(k.to_i, parser.parse(v['value']))
    end
    res
  end

  def all_const_calls
    res = []
    res << self.clone if has_const_receiver?
    self.each do |e|
      if e.class == Sexp
        res.concat(e.all_const_calls)
      end
    end
    res
  end

  def first_const_call
    calls = all_const_calls
    return nil if calls.count == 0
    calls.first
  end
end


module Infrarecord

  class Parser

    attr_accessor :parser, :ruby2ruby

    def initialize
      @parser = Ruby19Parser.new
      @ruby2ruby = Ruby2Ruby.new
    end

    def parse(a_string)
      @parser.parse(a_string)
    end

    def first_possible_orm_call(a_string, bindings)
      possible_call = parse(a_string).first_const_call
      return nil if possible_call.nil?
      return nil if possible_call.method_name == "new" # TODO white-/blacklist?
      return @ruby2ruby.process(possible_call.replace_args_with_bindings(bindings))
    end

  end

end

