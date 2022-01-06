# frozen_string_literal: true

require_relative "../routine"

module Goru
  module Routines
    # [public]
    #
    class IO < Routine
      def initialize(state = nil, io:, intent: :rw, &block)
        super(state, &block)

        @io = io
        @intent = intent
        @status = :selecting
      end

      # [public]
      #
      attr_reader :io, :intent

      # [public]
      #
      def accept
        @io.accept_nonblock
      end

      # [public]
      #
      def read(bytes)
        result = @io.read_nonblock(bytes, exception: false)

        case result
        when :wait_readable, nil
          # nothing to do
        else
          result
        end
      end
    end
  end
end
