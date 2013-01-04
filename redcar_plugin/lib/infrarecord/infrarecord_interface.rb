
require "uri"
require "net/http"
require "json"

module Redcar

  class InfraRecord 

    class InfraRecordInterface

      def initialize
        @parser = Redcar::InfraRecord::SyntaxChecker.new
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

      def extract_nonliteral_arg_indices(a_call_node)
	#p a_call_node.to_json
	#p a_call_node.raw_node.methods.sort
	#p a_call_node.all_child_nodes.map {|n| 
	#  n.as_code}
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
      
      def predict_orm_call_on_line(a_string)
        # check syntax before sending an acutal request
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
	arg_idxs = extract_nonliteral_arg_indices(parent)
	p arg_idxs
	predict_orm_call(a_string)
      end

      def predict_orm_call(a_string)
        params = {'statement' => a_string}
        res = http_post("http://localhost:3000/infrarecord", params)
        res = JSON.parse(res)
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
