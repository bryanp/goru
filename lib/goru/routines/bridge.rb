# frozen_string_literal: true

require_relative "../routine"

module Goru
  module Routines
    # [public]
    #
    class Bridge < Routine
      def initialize(state = nil, routine:, channel:, &block)
        super(state, &block)

        @routine = routine
        @channel = channel
        @channel.add_observer(self)
      end

      # [public]
      #
      def ready?
        @status == :ready
      end

      private def status_changed
        case @status
        when :finished
          @channel.remove_observer(self)
        end

        super
      end

      def channel_received
        update_status
      end

      def channel_read
        update_status
      end

      def channel_closed
        update_status
      end
    end
  end
end
