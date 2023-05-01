# frozen_string_literal: true

require "goru/scheduler"

RSpec.describe "routine status" do
  let(:scheduler) {
    Goru::Scheduler.new
  }

  describe "initial status" do
    it "is ready" do
      scheduled_routine = scheduler.go { |routine|
        routine.finished
      }

      expect(scheduled_routine.status).to eq(:ready)
    end
  end

  context "routine is sleeping" do
    it "is idle" do
      scheduled_routine = scheduler.go { |routine|
        case routine.state
        when :sleeping
          routine.finished
        else
          routine.update(:sleeping)
          routine.sleep(0.2)
        end
      }

      sleep(0.1)

      expect(scheduled_routine.status).to eq(:idle)
    end
  end

  context "routine has errored" do
    it "is errored" do
      scheduled_routine = scheduler.go { |routine|
        routine.debug = false
        fail
      }

      scheduler.wait

      expect(scheduled_routine.status).to eq(:errored)
    end
  end

  context "routine has finished" do
    it "is finished" do
      scheduled_routine = scheduler.go { |routine|
        routine.finished
      }

      scheduler.wait

      expect(scheduled_routine.status).to eq(:finished)
    end
  end
end
