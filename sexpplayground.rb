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

