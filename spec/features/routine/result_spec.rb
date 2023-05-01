# frozen_string_literal: true

require "goru/scheduler"

RSpec.describe "getting a routine's result" do
  let(:scheduler) {
    Goru::Scheduler.new
  }

  context "routine finished normally" do
    it "has a result" do
      scheduled_routine = scheduler.go { |routine|
        routine.finished(:fin)
      }

      scheduler.wait

      expect(scheduled_routine.result).to eq(:fin)
    end
  end

  context "routine errored" do
    it "re-raises the error" do
      scheduled_routine = scheduler.go { |routine|
        routine.debug = false
        fail "something went wrong"
      }

      scheduler.wait

      expect {
        scheduled_routine.result
      }.to raise_error("something went wrong")
    end

    it "exposes the error" do
      scheduled_routine = scheduler.go { |routine|
        routine.debug = false
        fail "something went wrong"
      }

      scheduler.wait

      expect(scheduled_routine.error.message).to eq("something went wrong")
    end
  end
end
