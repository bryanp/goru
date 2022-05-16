# frozen_string_literal: true

require_relative "../routine"
require_relative "bridge"

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
        @monitor = nil
      end

      # [public]
      #
      attr_reader :io, :intent

      attr_writer :monitor

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
          finished

          nil
        when :wait_readable
          # nothing to do
        else
          result
        end
      end

      # [public]
      #
      def write(data)
        result = @io.write_nonblock(data, exception: false)

        case result
        when nil
          finished

          nil
        when :wait_writable
          # nothing to do
        else
          result
        end
      end

      # [public]
      #
      def intent=(intent)
        intent = intent.to_sym

        # TODO: Validate intent (move validation from scheduler into the routines).
        #
        @monitor.interests = intent
        @intent = intent
      end

      # [public]
      #
      def bridge(channel)
        bridge = Bridge.new(routine: self, channel: channel)
        @reactor.adopt_routine(bridge)
      end
    end
  end
end
