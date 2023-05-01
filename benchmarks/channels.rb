# frozen_string_literal: true

require_relative "../lib/goru"

class Reader
  include Goru

  def initialize(channel:)
    @received = []

    go(channel: channel, intent: :r) { |routine|
      value = routine.read
      @received << value
    }
  end

  attr_reader :received
end

class Writer
  include Goru

  def initialize(channel:, values:)
    go(channel: channel, intent: :w) { |routine|
      if (value = values.shift)
        routine << value
      else
        channel.close
        routine.finished
      end
    }
  end
end

values = 100_000.times.to_a
channel = Goru::Channel.new

start = Time.now
Reader.new(channel: channel)
Writer.new(channel: channel, values: values)

Goru::Scheduler.wait
puts Time.now - start
