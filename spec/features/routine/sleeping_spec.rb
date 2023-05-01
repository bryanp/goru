# frozen_string_literal: true

require "goru/scheduler"

RSpec.describe "sleeping in a routine" do
  let(:scheduler) {
    Goru::Scheduler.new
  }

  it "sleeps" do
    slept_at = nil

    scheduler.go { |routine|
      slept_at = Time.now
      routine.sleep(0.1)
      routine.finished
    }

    scheduler.wait

    expect(Time.now - slept_at).to be_within(0.01).of(0.1)
  end

  it "cannot sleep forever" do
    captured_error = nil

    scheduler.go { |routine|
      begin
        routine.sleep
      rescue => error
        captured_error = error
      ensure
        routine.finished
      end
    }

    scheduler.wait

    expect(captured_error).to be_instance_of(ArgumentError)
  end
end
