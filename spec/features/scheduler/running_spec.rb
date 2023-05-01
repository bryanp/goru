# frozen_string_literal: true

require "goru/scheduler"

RSpec.describe "scheduling and running routines" do
  let(:scheduler) {
    Goru::Scheduler.new
  }

  it "runs a routine until finished" do
    values = []

    scheduler.go { |routine|
      values << rand
      routine.finished if values.count == 10
    }

    scheduler.wait

    expect(values.count).to eq(10)
  end

  it "runs two routines until finished" do
    values = []

    scheduler.go { |routine|
      values << 0
      routine.finished if values.count { |value|
        value == 0
      } == 5
    }

    scheduler.go { |routine|
      values << 1
      routine.finished if values.count { |value|
        value == 1
      } == 5
    }

    scheduler.wait

    expect(values.count { |value| value == 0 }).to eq(5)
    expect(values.count { |value| value == 1 }).to eq(5)
  end
end
