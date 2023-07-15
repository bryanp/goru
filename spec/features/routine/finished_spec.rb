# frozen_string_literal: true

require "goru/scheduler"

RSpec.describe "checking if a routine is finished" do
  let(:scheduler) {
    Goru::Scheduler.new
  }

  it "is finished if finished" do
    routine = scheduler.go { |routine|
      routine.finished
    }

    scheduler.wait

    expect(routine.finished?).to be(true)
  end

  it "is finished if errored" do
    routine = scheduler.go { |routine|
      routine.debug = false

      fail
    }

    scheduler.wait

    expect(routine.finished?).to be(true)
  end

  it "is not finished when running" do
    is_finished = nil

    scheduler.go { |routine|
      is_finished = routine.finished?
      routine.finished
    }

    scheduler.wait

    expect(is_finished).to be(false)
  end

  it "is not finished when idle" do
    routine = scheduler.go { |routine|
      case routine.state
      when :sleeping
        routine.finished
      else
        routine.update(:sleeping)
        routine.sleep(0.1)
      end
    }

    routine.add_observer do
      case routine.status
      when Goru::Routine::STATUS_IDLE
        @finished_when_idle = routine.finished?
      end
    end

    scheduler.wait

    expect(@finished_when_idle).to be(false)
  end
end
