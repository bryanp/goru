# frozen_string_literal: true

require "http"
require "llhttp"
require "socket"

require "goru/scheduler"

require_relative "../../support/delegate"

class NonBlockingServer
  def initialize
    @scheduler = Goru::Scheduler.new
  end

  def start
    @server = TCPServer.new("localhost", 4243)

    @routine = @scheduler.go(io: @server, intent: :r) { |server_routine|
      if (client_io = server_routine.accept)
        state = {delegate: Delegate.new}
        state[:parser] = LLHttp::Parser.new(state[:delegate])

        @scheduler.go(state, io: client_io, intent: :r) { |client_routine|
          if (data = client_routine.read(16384))
            client_routine.state[:parser] << data

            if client_routine.state[:delegate].message_complete?
              client_routine.write("HTTP/1.1 204 No Content\r\n")
              client_routine.write("content-length: 0\r\n\r\n")

              client_routine.state[:delegate].reset
              client_routine.state[:parser].reset
              client_routine.finished
            end
          end
        }
      end
    }
  end

  def stop
    @scheduler.stop
    @server.close
  end
end

RSpec.describe "using non-blocking io" do
  let(:server) {
    NonBlockingServer.new
  }

  it "handles io" do
    server.start

    # wait a second for the server to start
    sleep(0.25)

    statuses = 100.times.map {
      HTTP.get("http://localhost:4243").status.to_i
    }

    server.stop

    expect(statuses.count).to eq(100)
    expect(statuses.uniq.count).to eq(1)
    expect(statuses.uniq[0]).to eq(204)
  end
end
