# frozen_string_literal: true

require "goru/scheduler"

RSpec.describe "configuring the scheduler" do
  it "can be configured with a reactor count" do
    expect {
      Goru::Scheduler.new(count: 1)
    }.not_to raise_error
  end
end
