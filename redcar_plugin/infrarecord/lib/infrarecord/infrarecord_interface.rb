
require "uri"
require "net/http"
require "json"

module Redcar

  class InfraRecord

    class InfraRecordInterface

      attr_reader :controller
      
      def initialize(owning_controller)
        @parser = Redcar::InfraRecord::SyntaxChecker.new
        @controller = owning_controller
      end

      def http_get(url)
        url = URI.parse(url)
        req = Net::HTTP::Get.new(url.path)
        res = Net::HTTP.start(url.host, url.port) {|http|
          http.request(req)
        }
        res.body
      end

      def http_post(url, data)
        return Net::HTTP.post_form(URI.parse(url), data).body
      end

      def nonliteral_args(a_call_node)
       i = 0
       res = {}
       args_node = a_call_node.args_node
       if a_call_node.args_node.respond_to?(:child_nodes)
         args_node.child_nodes.each do |node|
           if node.respond_to?(:get_name)
             tmp_node = Node.new(node, nil)
             if tmp_node.is_call_node?
                res[i] = node.getReceiverNode().getName() + "." + node.get_name + "()"
             elsif tmp_node.is_fcall_node?
                res[i] = node.getName() + "()"
             else
                res[i] = node.get_name
             end
           end
           i += 1
         end
       else
         []
       end
       res
      end

      def nonliteral_args_in_call(line_number)
        node, statement  = potential_orm_call_node(line_number)
        return nil if node == nil
        return nonliteral_args(node)
      end

      def potential_orm_call_node(line_number)
        "Find a potential ORM call on line line_number.
         If a potential model name is found but the rest of the line does 
         not parse correctly, look ahead a given number of lines for the statement
         to complete.
         Answer a tuple [call_node, statement_containing_the_full_call]."
        line = controller.get_line(line_number)
        line_offset = 1
        statement = line
        node = nil
  
        while node.nil? and line_offset < 10 # FIXME maximum line offset 
                                             # as config option
          node = @parser.check(statement)
          break if node
          statement += controller.get_line(line_number + line_offset)
          line_offset += 1
        end
        return nil, nil if node.nil?
        const_node = node.find_const_node
        return nil, nil if const_node.nil?
        parent = const_node.parent_node
        return nil if not parent.is_call_node?
        return [parent, statement]
      end

      def predict_orm_call_on_line(line_number, context)
        node, statement = potential_orm_call_node(line_number)
        return if not node
        arg_idxs = nonliteral_args(node)
        predict_orm_call(statement, context)
      end

      def predict_orm_call(a_string, context)
        params = {'statement' => a_string,
                  'context'   => context }
        res = http_post("http://localhost:3000/infrarecord", params)
        res = JSON.parse(res)
        p "This is the result: "
        p res
        result_hash = {:rows => res['rows'], :query => res['query']}
        if res['status'] != 'not-found'
          result_hash
        else
          nil
        end
      end
    end
  end
end
