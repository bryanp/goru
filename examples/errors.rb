# frozen_string_literal: true

require_relative "../lib/goru"

class Errored
  include Goru

  def initialize
    # Custom error handler.
    #
    go { |routine|
      routine.handle(StandardError) do |event:|
        puts "!!! #{event}"
      end

      fail "[custom] something went wrong: #{SecureRandom.hex}"
    }

    # Default error handler.
    #
    go { |routine|
      fail "[default] something went wrong: #{SecureRandom.hex}"
    }
  end
end

Errored.new
