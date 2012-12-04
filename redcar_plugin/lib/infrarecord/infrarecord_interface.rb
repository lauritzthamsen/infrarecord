
require "uri"
require "net/http"
require "json"

module Redcar

  class InfraRecord 

    class InfraRecordInterface

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

      def predict_orm_call(a_string)
        params = {'statement' => a_string}
        res = http_post("http://localhost:4567/", params)
        res = JSON.parse(res)
        if res['status'] != 'not-found'
          res['query']
        else
          nil
        end
      end
    end
  end
end
