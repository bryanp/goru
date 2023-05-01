# frozen_string_literal: true

require "goru/scheduler"

RSpec.describe "clearing a channel" do
  let(:scheduler) {
    Goru::Scheduler.new
  }

  let(:channel) {
    Goru::Channel.new
  }

  it "clears the channel" do
    count = 10
    values = count.times.to_a
    received = []

    scheduler.go(:read, channel: channel, intent: :r) { |routine|
      case routine.state
      when :read
        received << routine.read
        routine.finished if channel.empty?
        routine.update(:sleep)
      when :sleep
        routine.sleep(0.1)
        routine.update(:read)
      end
    }

    scheduler.go(channel: channel, intent: :w) { |routine|
      if (value = values.shift)
        routine << value
      else
        channel.clear
        routine.finished
      end
    }

    scheduler.wait

    expect(received).to eq([0])
  end
end
