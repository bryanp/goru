# frozen_string_literal: true

require_relative "../routine"

module Goru
  module Routines
    # [public]
    #
    class IO < Routine
      def initialize(state = nil, io:, intent:, &block)
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
        when nil
          @status = :finished

          nil
        when :wait_readable
          # nothing to do
        else
          result
        end
      end

      # TODO: Implement `write`.
    end
  end
end
