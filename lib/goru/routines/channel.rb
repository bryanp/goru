# frozen_string_literal: true

require_relative "../routine"

module Goru
  module Routines
    # [public]
    #
    class Channel < Routine
      def initialize(state = nil, channel:, &block)
        super(state, &block)

        @channel = channel
        @channel.add_observer(self)
      end

      private def status_changed
        case @status
        when :ready
          @reactor&.wakeup
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
