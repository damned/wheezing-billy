require 'reel'
require 'celluloid-http'

class ProxyRequest < Celluloid::Http::Request
  def self.from_request(request)
    self.new("http://#{request.headers["Host"]}#{request.path}", {
      method: request.method,
      raw_body: request.body
    })
  end
end

class ProxyResponse < Celluloid::Http::Response

  def self.from_response(response)
    headers = response.headers.dup
    headers.delete 'Proxy-Connection'
    self.new( response.status, headers, response.body)
  end

end

addr, port = '127.0.0.1', 1234

puts "*** Starting proxy server on http://#{addr}:#{port}"
Reel::Server::HTTP.run(addr, port, spy: true) do |connection|
  connection.each_request do |request|
    puts request.url
    begin
      outbound = ProxyRequest.from_request request
    rebound = Celluloid::Http.send_request outbound
    response = ProxyResponse.from_response rebound
    connection.respond response.sym_status, response.headers, response.body
    puts "responded"
    rescue => e
      STDERR.puts 'bad request - skipping ' + request.url
      STDERR.puts 'bad request - error: ' + e.to_s
      request.respond 404
    end
  end
end

