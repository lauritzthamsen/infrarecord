require 'ruby_parser'
require 'ruby2ruby'

class Sexp
  
  def is_call?
    count > 2 and self[0] == :call
  end
  
  def has_receiver?
    is_call? and self[1] != nil
  end
  
  def has_const_receiver?
    has_receiver? and self[1][0] == :const
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


rp = RubyParser.new
rr = Ruby2Ruby.new
s1 = rp.parse('Foo.bar')
s2 = rp.parse('foo.bar')
s3 = rp.parse('Foo.bar(x, 4)')

s4 = Sexp.from_array([:call, nil, :x])
s5 = Sexp.from_array([:lit, 3])

s6 = s3.recursive_replace(s4, s5)
s7 = s6.replace_arg_in_const_call(1, [:lit, 5])

puts s1.has_const_receiver?
puts s2.has_const_receiver?
p s3.args
p s7
puts rr.process(s7)

s8 = rp.parse('a = Foo.bar(Baz.x, y)')
p rr.process(s8.first_const_call)

s9 = rp.parse('Foo.bar(1, d, e)')
b = {'2' => {'value' => "5", 'name' => 'e'}, 
     '1' => {'value' => "\"baz\"", 'name' => 'd'}}
s10 = s9.replace_args_with_bindings(b)
p s10
p rr.process(s10)


