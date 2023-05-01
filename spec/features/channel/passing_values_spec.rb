# frozen_string_literal: true

require "goru/scheduler"

RSpec.describe "passing values through a channel" do
  let(:scheduler) {
    Goru::Scheduler.new
  }

  let(:channel) {
    Goru::Channel.new
  }

  it "reads and writes values" do
    count = 10
    values = count.times.to_a
    received = []

    scheduler.go(channel: channel, intent: :r) { |routine|
      received << routine.read
      routine.finished if received.count == count
    }

    scheduler.go(:write, channel: channel, intent: :w) { |routine|
      case routine.state
      when :write
        if (value = values.shift)
          routine << value
          routine.update(:sleep)
        else
          routine.finished
        end
      when :sleep
        routine.sleep(rand / 100)
        routine.update(:write)
      end
    }

    scheduler.wait

    expect(received).to eq(count.times.to_a)
  end
end
