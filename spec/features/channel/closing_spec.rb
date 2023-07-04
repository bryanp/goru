# frozen_string_literal: true

require "goru/scheduler"

RSpec.describe "closing a channel" do
  let(:scheduler) {
    Goru::Scheduler.new
  }

  let(:channel) {
    Goru::Channel.new
  }

  it "automatically finishes read routines" do
    count = 10
    values = count.times.to_a
    received = []

    scheduler.go(channel: channel, intent: :r) { |routine|
      received << routine.read
    }

    scheduler.go(:write, channel: channel, intent: :w) { |routine|
      case routine.state
      when :write
        if (value = values.shift)
          routine << value
        else
          channel.close
          routine.finished
        end
      when :sleep
        routine.sleep(rand)
      end
    }

    scheduler.wait

    expect(received).to eq(count.times.to_a)
  end

  it "automatically finishes write routines" do
    count = 10
    received = []

    scheduler.go(channel: channel, intent: :r) { |routine|
      received << routine.read
      channel.close if received.count == count
    }

    scheduler.go(:write, channel: channel, intent: :w) { |routine|
      case routine.state
      when :write
        routine << rand
        routine.update(:sleep)
      when :sleep
        routine.update(:write)
        routine.sleep(rand / 100)
      end
    }

    scheduler.wait

    expect(received.count).to eq(count)
  end
end
