require "uri"
require "net/http"
require "json"

def http_post(url, data)
  return Net::HTTP.post_form(URI.parse(url), data).body
end

bindings = {0 => {:name => 'id', :value => '1337'}}
data = {:statement => 'Post.find(id)',
        :bindings => JSON.unparse(bindings)}
p http_post('http://localhost:3000/infrarecord/', data)

bindings = {0 => {:name => 'title', :value => '"The Title"'}}
data = {:statement => 'Post.find_by_title(title)',
        :bindings => JSON.unparse(bindings)}
p http_post('http://localhost:3000/infrarecord/', data)
