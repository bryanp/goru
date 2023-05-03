# frozen_string_literal: true

require_relative "../spec/support/server"

server = Server.new
server.start

sleep(1)

puts "making requests..."
puts "got: #{HTTP.get("http://localhost:4242").status}"
puts "got: #{HTTP.get("http://localhost:4242").status}"
puts "got: #{HTTP.get("http://localhost:4242").status}"

puts "shutting down..."
server.stop
