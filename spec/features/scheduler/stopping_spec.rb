# frozen_string_literal: true

require "goru/scheduler"

RSpec.describe "stopping the scheduler" do
  let(:scheduler) {
    Goru::Scheduler.new
  }

  it "immediately stops without waiting on routines to finish" do
    values = []

    scheduler.go { |routine|
      routine.sleep(0.1)
      values << rand
    }

    scheduler.stop

    expect(values.count).to eq(0)
  end
end
