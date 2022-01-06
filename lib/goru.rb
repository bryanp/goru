# frozen_string_literal: true

require "is/extension"

module Goru
  require_relative "goru/scheduler"
  require_relative "goru/version"

  extend Is::Extension

  def go(state = nil, io: nil, intent: :rw, &block)
    Scheduler.go(state, io: io, intent: intent, &block)
  end
end

at_exit { Goru::Scheduler.wait }
