# frozen_string_literal: true

require "goru/scheduler"

RSpec.describe "handling errors in a routine" do
  let(:scheduler) {
    Goru::Scheduler.new
  }

  it "can handle errors" do
    handled = nil

    scheduler.go(:foo) { |routine|
      routine.debug = false
      routine.handle(StandardError) do |event:|
        handled = true
      end

      fail
    }

    scheduler.wait

    expect(handled).to be(true)
  end
end
