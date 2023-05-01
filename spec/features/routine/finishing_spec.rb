# frozen_string_literal: true

require "goru/scheduler"

RSpec.describe "finishing a routine" do
  let(:scheduler) {
    Goru::Scheduler.new
  }

  it "finishes" do
    values = []

    scheduler.go { |routine|
      values << rand
      routine.finished
    }

    scheduler.wait

    expect(values.count).to eq(1)
  end

  it "finishes with a value" do
    scheduled_routine = scheduler.go { |routine|
      routine.finished(:fin)
    }

    scheduler.wait

    expect(scheduled_routine.result).to eq(:fin)
  end
end
