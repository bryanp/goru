# frozen_string_literal: true

require_relative "../lib/goru"

def current_memory_usage
  `ps -o rss #{Process.pid}`.lines.last.to_i
end

$size = 10_000

class Profiler
  include Goru

  def initialize(size:)
    @size = size
  end

  def call
    @size.times do
      go(true) { |routine|
        if routine.state
          routine.update(false)
          routine.sleep(rand)
        else
          routine.finished
        end
      }
    end
  end
end

profiler = Profiler.new(size: $size)

starting_memory_usage = current_memory_usage

profiler.call

total_memory_usage_in_bytes = (current_memory_usage - starting_memory_usage).to_f * 1024
puts "#{total_memory_usage_in_bytes / $size} bytes per routine"
