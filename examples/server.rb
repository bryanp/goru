# frozen_string_literal: true

require "http"
require "llhttp"
require "socket"

require_relative "../lib/goru"

class Delegate < LLHttp::Delegate
  def initialize
    reset
  end

  def reset
    @message_complete = false
  end

  def message_complete?
    @message_complete == true
  end

  def on_message_complete
    @message_complete = true
  end
end

class Server
  include Goru

  def start
    go(io: TCPServer.new("localhost", 4242), intent: :r) { |server_routine|
      if (client_io = server_routine.accept)
        state = {delegate: Delegate.new}
        state[:parser] = LLHttp::Parser.new(state[:delegate])

        go(state, io: client_io, intent: :r) { |client_routine|
          if (data = client_routine.read(16384))
            client_routine.state[:parser] << data

            if client_routine.state[:delegate].message_complete?
              client_routine.write("HTTP/1.1 204 No Content\r\n")
              client_routine.write("content-length: 0\r\n\r\n")

              client_routine.state[:delegate].reset
              client_routine.state[:parser].reset
            end
          end
        }
      end
    }
  end
end

server = Server.new
server.start

sleep(1)

puts "making requests..."
pp HTTP.get("http://localhost:4242").to_s
pp HTTP.get("http://localhost:4242").to_s
pp HTTP.get("http://localhost:4242").to_s

puts "shutting down..."
Goru::Scheduler.stop
