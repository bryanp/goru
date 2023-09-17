# frozen_string_literal: true

require "goru/scheduler"

RSpec.describe "closing the io object" do
  let(:scheduler) {
    Goru::Scheduler.new
  }

  let(:io) {
    double(:io)
  }

  it "closes the io when the routine is finished" do
    expect(io).to receive(:close)

    scheduler.go(intent: :read, io: io) { |routine|
      routine.finished
    }

    scheduler.wait
  end
end
