# frozen_string_literal: true

require_relative "../lib/goru"

channel = Goru::Channel.new(size: 3)

class Reader
  include Goru

  def initialize(channel:)
    @received = []

    go(:sleep, channel: channel, intent: :r) { |routine|
      case routine.state
      when :sleep
        routine.sleep(rand)
        routine.update(:read)
      when :read
        if (value = routine.read)
          @received << value
          puts "received: #{value}"
          routine.update(:sleep)
        else
          routine.finished
        end
      end
    }
  end

  attr_reader :received
end

class Writer
  include Goru

  def initialize(channel:)
    @writable = 10.times.to_a
    values = @writable.dup

    go(channel: channel, intent: :w) { |routine|
      if (value = values.shift)
        routine << value
        puts "wrote: #{value}"
      else
        routine.finished
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
  elsif Time.now - start > 5
    fail "timed out"
  else
    sleep(0.1)
  end
end

puts "all received after #{Time.now - start}"
Goru::Scheduler.stop
