# frozen_string_literal: true

require "http"
require "socket"

require "goru/scheduler"

require_relative "../../support/delegate"

class BridgeServer
  def initialize
    @scheduler = Goru::Scheduler.new
    @writer = Goru::Channel.new
  end

  def start
    @scheduler.go(io: TCPServer.new("localhost", 4242), intent: :r) { |server_routine|
      if (client_io = server_routine.accept)
        state = {delegate: Delegate.new, status: :read}
        state[:parser] = LLHttp::Parser.new(state[:delegate])

        @scheduler.go(state, io: client_io, intent: :r) { |client_routine|
          case client_routine.intent
          when :r
            if (data = client_routine.read(16384))
              client_routine.state[:parser] << data

              if client_routine.state[:delegate].message_complete?
                client_routine.intent = :w
                # client_routine.bridge(@writer, intent: :w)
                # client_routine.state[:status] = :write
              end
            end
          when :w
            # client_routine.write("HTTP/1.1 204 No Content\r\n")
          end

          # if client_routine.state[:status] == :read
          #   if (data = client_routine.read(16384))
          #     client_routine.state[:parser] << data

          #     if client_routine.state[:delegate].message_complete?
          #       client_routine.intent = :w
          #       client_routine.bridge(@writer, intent: :w)
          #       client_routine.state[:status] = :write
          #     end
          #   end
          # end

          # if client_routine.state[:status] == :write
          #   puts "writ"
          #   @writer << "HTTP/1.1 204 No Content\r\n"
          #   @writer << "content-length: 0\r\n\r\n"
          #   @writer.close

          #   client_routine.state[:delegate].reset
          #   client_routine.state[:parser].reset
          #   client_routine.state[:status] = :read
          # end
        }
      end
    }
  end

  def stop
    @scheduler.stop
  end
end

RSpec.xdescribe "writes using a bridge" do
  let(:server) {
    BridgeServer.new
  }

  it "handles io" do
    server.start

    # wait a second for the server to start
    sleep(0.25)

    statuses = 100.times.map {
      HTTP.get("http://localhost:4242").status.to_i
    }

    server.stop

    expect(statuses.count).to eq(100)
    expect(statuses.uniq.count).to eq(1)
    expect(statuses.uniq[0]).to eq(204)
  end
end
