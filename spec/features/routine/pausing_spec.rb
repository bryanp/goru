# frozen_string_literal: true

require "goru/scheduler"

RSpec.describe "pausing a routine" do
  let(:scheduler) {
    Goru::Scheduler.new
  }

  it "pauses and resumes" do
    values = []

    routine = scheduler.go { |routine|
      values << rand
      routine.finished if values.count == 2
      routine.pause
    }

    sleep(0.1)
    routine.resume
    scheduler.wait

    expect(values.count).to eq(2)
  end
end
