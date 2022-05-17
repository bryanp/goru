# frozen_string_literal: true

require "ruby-prof"

require_relative "../lib/goru"

class Worker
  include Goru

  def initialize
    @results = []
  end

  attr_reader :results

  def call
    100_000.times do |index|
      go(0) { |routine|
        state = routine.state

        if state >= 10
          routine.finished
        else
          @results << :result
          routine.update(state + 1)
        end
      }
    end
  end
end

worker = Worker.new

result = RubyProf.profile do
  worker.call
  Goru::Scheduler.wait
end

printer = RubyProf::FlatPrinter.new(result)
printer.print(STDOUT, {})
