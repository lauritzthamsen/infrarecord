require 'net/http'
require 'json'

ARGV.each do |a|
  file = File.open(a)

  if file
    i = 1
    while !file.eof?
      response = Net::HTTP.post_form(URI("http://localhost:4567/"), {:statement => file.readline})
      response = JSON.parse(response.body)

      puts "#{i}: #{response["query"]}" if response["status"] == "sql"

      i += 1
    end
  end
end
