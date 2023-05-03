# frozen_string_literal: true

require "http"
require "llhttp"
require "socket"

require_relative "delegate"
require_relative "../../lib/goru"

class Server
  include Goru

  def start
    @server = TCPServer.new("localhost", 4242)

    @routine = go(io: @server, intent: :r) { |server_routine|
      server_routine.debug = true

      accept(routine: server_routine)
    }
  end

  def stop
    @server.close
    @routine.finished
  end

  def accept(routine:)
    if (client_io = routine.accept)
      delegate = Delegate.new
      parser = LLHttp::Parser.new(delegate)
      writer = Goru::Channel.new
      state = {delegate: delegate, parser: parser, writer: writer}

      go(state, io: client_io, intent: :r) { |client_routine|
        client_routine.debug = true

        case client_routine.intent
        when :r
          read(routine: client_routine)
        when :w
          write(routine: client_routine)
        end
      }
    end
  end

  def read(routine:)
    if (data = routine.read(16_384))
      routine.state[:parser] << data

      if routine.state[:delegate].message_complete?
        dispatch(routine: routine)
      end
    end
  end

  def write(routine:)
    if (writable = routine.state[:writer].read)
      routine.write(writable)
    elsif routine.state[:writer].closed?
      routine.state[:delegate].reset
      routine.state[:parser].reset
      routine.finished
    end
  end

  def dispatch(routine:)
    writer = routine.state[:writer]

    routine.bridge({mode: :sleep}, intent: :w, channel: writer) { |bridge_routine|
      bridge_routine.debug = true

      case bridge_routine.state[:mode]
      when :sleep
        bridge_routine.sleep(rand)
        bridge_routine.state[:mode] = :write
      else
        bridge_routine << <<~RESPONSE
          HTTP/1.1 204 No Content\r
          Content-Length: 0\r
          \r
        RESPONSE

        bridge_routine.finished
        writer.close
      end
    }
  end
end
