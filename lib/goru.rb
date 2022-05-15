# frozen_string_literal: true

require "is/extension"

module Goru
  require_relative "goru/scheduler"
  require_relative "goru/version"

  extend Is::Extension

  def go(state = nil, io: nil, channel: nil, intent: nil, &block)
    Scheduler.go(state, io: io, channel: channel, intent: intent, &block)
  end
end

at_exit { Goru::Scheduler.wait }
