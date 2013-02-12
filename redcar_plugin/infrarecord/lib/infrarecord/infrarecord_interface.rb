
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

      def nonliteral_args_in_call(a_string)
       node = potential_orm_call_node(a_string)
       return nil if node == nil
       return nonliteral_args(node)
      end

      def potential_orm_call_node(a_string)
        node = @parser.check(a_string)
        return nil if node == nil
        const_node = node.find_const_node
        if const_node == nil
          return nil
        end
        parent = const_node.parent_node
        if not parent.is_call_node?
          return nil
        end
        parent
      end

      def predict_orm_call_on_line(line_number, context)
        line = controller.get_line(line_number)
        node = potential_orm_call_node(line)
        puts "line number is #{line_number}, line is '#{line}'"
        return if not node
        arg_idxs = nonliteral_args(node)
        statement = line #FIXME: Parse line, add additional lines 
                         # if it does not parse correctly
        #p arg_idxs
        predict_orm_call(statement, context)
      end

      def predict_orm_call(a_string, context)
        params = {'statement' => a_string,
                  'context'   => context }
        res = http_post("http://localhost:3000/infrarecord", params)
        res = JSON.parse(res)
        #p "This is the result: "
        #p res
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
