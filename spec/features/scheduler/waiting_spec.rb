# frozen_string_literal: true

require "goru/scheduler"

RSpec.describe "waiting on the scheduler" do
  let(:scheduler) {
    Goru::Scheduler.new
  }

  it "waits on routines to finish" do
    values = []
    slept_at = nil

    scheduler.go { |routine|
      slept_at = Time.now
      routine.sleep(0.1)
      values << rand
      routine.finished
    }

    scheduler.wait

    expect(values.count).to eq(1)
    expect(Time.now - slept_at).to be_within(0.01).of(0.1)
  end
end
