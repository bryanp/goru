# frozen_string_literal: true

require "goru/scheduler"

RSpec.describe "observing a routine" do
  let(:scheduler) {
    Goru::Scheduler.new
  }

  context "observer is an object" do
    let(:observer) {
      Class.new {
        def initialize
          @calls = []
        end

        attr_reader :calls

        def routine_status_changed
          @calls << :call
        end
      }.new
    }

    it "is notified of each status change" do
      routine = scheduler.go { |routine|
        case routine.state
        when :sleeping
          routine.finished
        else
          routine.update(:sleeping)
          routine.sleep(0.1)
        end
      }

      routine.add_observer(observer)
      scheduler.wait

      expect(observer.calls.count).to eq(4)
    end
  end

  context "observer is a block" do
    it "is notified of each status change" do
      routine = scheduler.go { |routine|
        case routine.state
        when :sleeping
          routine.finished
        else
          routine.update(:sleeping)
          routine.sleep(0.1)
        end
      }

      statuses = []
      routine.add_observer do
        statuses << routine.status
      end

      scheduler.wait

      expect(statuses).to eq([
        :ready,
        :idle,
        :ready,
        :finished
      ])
    end
  end
end
