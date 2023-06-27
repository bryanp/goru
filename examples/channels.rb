# frozen_string_literal: true

require_relative "../lib/goru"

channel = Goru::Channel.new

class Reader
  include Goru

  def initialize(channel:)
    @received = []

    go(channel: channel, intent: :r) { |routine|
      value = routine.read
      @received << value
      puts "received: #{value}"
    }
  end

  attr_reader :received
end

class Writer
  include Goru

  def initialize(channel:)
    @writable = 10.times.to_a
    values = @writable.dup

    go(:sleep, channel: channel, intent: :w) { |routine|
      case routine.state
      when :sleep
        routine.update(:write)
        routine.sleep(rand)
      when :write
        if (value = values.shift)
          routine << value
          routine.update(:sleep)
          puts "wrote: #{value}"
        end

        if values.empty?
          channel.close
          routine.finished
        end
      end
    }
  end

  attr_reader :writable
end

reader = Reader.new(channel: channel)
writer = Writer.new(channel: channel)
start = Time.now

loop do
  if reader.received == writer.writable
    break
  elsif Time.now - start > 10
    fail "timed out"
  else
    sleep(0.1)
  end
end

puts "all received after #{Time.now - start}"
Goru::Scheduler.stop
