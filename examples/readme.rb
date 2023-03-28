# frozen_string_literal: true

require_relative "../lib/goru"

class Sleeper
  include Goru

  def call
    go(:running) { |routine|
      case routine.state
      when :running
        routine.update(:sleeping)
        routine.sleep(rand)
      when :sleeping
        puts "[#{object_id}] woke up at #{Time.now.to_f}"
        routine.update(:running)
      end
    }
  end
end

3.times do
  sleeper = Sleeper.new
  sleeper.call
end
