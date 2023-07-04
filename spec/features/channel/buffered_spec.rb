# frozen_string_literal: true

require "goru/scheduler"

RSpec.describe "using channels as buffers" do
  let(:scheduler) {
    Goru::Scheduler.new
  }

  let(:channel) {
    Goru::Channel.new(size: 3)
  }

  it "reads and writes values" do
    count = 10
    values = count.times.to_a
    received = []

    scheduler.go(:sleep, channel: channel, intent: :r) { |routine|
      case routine.state
      when :read
        received << [routine.read, Time.now]
        routine.finished if received.count == count
        routine.update(:sleep)
      when :sleep
        routine.update(:read)
        routine.sleep(rand / 100)
      end
    }

    scheduler.go(channel: channel, intent: :w) { |routine|
      if (value = values.shift)
        routine << value
        routine.update(:sleep)
      else
        routine.finished
      end
    }

    scheduler.wait

    expect(received.count).to eq(count)
  end
end
