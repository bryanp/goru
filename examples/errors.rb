# frozen_string_literal: true

require_relative "../lib/goru"

class Errored
  include Goru

  def initialize
    # Custom error handler.
    #
    go { |routine|
      # TODO: Should we allow handlers to be defined here? I think not... just on the main object.
      #
      routine.handle(StandardError) do |event:|
        puts "!!! #{event}"
      end

      begin
        fail "[custom] something went wrong: #{SecureRandom.hex}"
      ensure
        routine.finished
      end
    }

    # Default error handler.
    #
    go { |routine|
      begin
        fail "[default] something went wrong: #{SecureRandom.hex}"
      ensure
        routine.finished
      end
    }
  end
end

Errored.new