# frozen_string_literal: true

require "goru/scheduler"

RSpec.describe "managing routine state" do
  let(:scheduler) {
    Goru::Scheduler.new
  }

  it "sets state" do
    scheduled_routine = scheduler.go(:foo) { |routine|
      routine.finished
    }

    scheduler.wait

    expect(scheduled_routine.state).to eq(:foo)
  end

  it "updates state" do
    scheduled_routine = scheduler.go(0) { |routine|
      routine.update(routine.state + 1)
      routine.finished
    }

    scheduler.wait

    expect(scheduled_routine.state).to eq(1)
  end
end
