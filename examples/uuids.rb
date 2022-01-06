# frozen_string_literal: true

require "get_process_mem"
require "securerandom"

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
          @results << SecureRandom.uuid
          routine.update(state + 1)
        end
      }

      # Use this to see how fast things are without concurrency.
      #
      # 10.times do |j|
      #   @results << SecureRandom.uuid
      # end
    end
  end
end

def mem
  GetProcessMem.new.mb.round(0)
end

start = Time.now
worker = Worker.new
worker.call

# Wait before we attempt to get results (ultimately need some kind of future).
#
Goru::Scheduler.wait

puts "got #{worker.results.count} in #{Time.now - start}, using #{mem}MB"
