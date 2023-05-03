# frozen_string_literal: true

require_relative "../spec/support/server"

server = Server.new
server.start

sleep(1)

begin
  puts "making requests..."
  puts "got: #{HTTP.timeout(1).get("http://localhost:4242").status}"
  puts "got: #{HTTP.timeout(1).get("http://localhost:4242").status}"
  puts "got: #{HTTP.timeout(1).get("http://localhost:4242").status}"
ensure
  puts "shutting down..."
  server.stop
end
