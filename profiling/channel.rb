# frozen_string_literal: true

require "ruby-prof"

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

values = 10_000.times.to_a
result = RubyProf.profile do
  channel = Goru::Channel.new
  reader = Reader.new(channel: channel)
  writer = Writer.new(channel: channel, values: values)
  Goru::Scheduler.wait
end

printer = RubyProf::FlatPrinter.new(result)
printer.print(STDOUT, {})
