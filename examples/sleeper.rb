# frozen_string_literal: true

require_relative "../lib/goru"

class Sleeper
  include Goru

  def call
    5.times do |index|
      go(true) { |routine|
        if routine.state
          routine.update(false)
          routine.sleep(rand)
        else
          puts "[#{index}] woke up at #{Time.now.to_f}"
          routine.update(true)
        end
      }
    end
  end
end

sleeper = Sleeper.new
sleeper.call
