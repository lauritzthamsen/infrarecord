
require "uri"
require "net/http"
require "json"

module InfrarecordInterface

def InfrarecordInterface.http_get(url)
  url = URI.parse(url)
  req = Net::HTTP::Get.new(url.path)
  res = Net::HTTP.start(url.host, url.port) {|http|
    http.request(req)
  }
  res.body
end

def InfrarecordInterface.http_post(url, data)
  return Net::HTTP.post_form(URI.parse(url), data).body
end

def InfrarecordInterface.predict_orm_call(a_string)
  params = {'statement' => a_string}
  res = http_post("http://localhost:4567/", params)
  res = JSON.parse(res)
  if res['status'] != 'not-found'
    puts res['query']
  end
end

end