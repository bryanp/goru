# frozen_string_literal: true

require_relative "../routine"

module Goru
  module Routines
    # [public]
    #
    class Channel < Routine
      def initialize(state = nil, channel:, intent:, &block)
        super(state, &block)

        @channel = channel
        @channel.observer = self
        @intent = intent
        @status = case @intent
        when :r
          :idle
        when :w
          :ready
        end
      end

      def channel_received
        @status = case @intent
        when :r
          :ready
        when :w
          if @channel.full?
            :idle
          else
            :ready
          end
        end

        @reactor&.wakeup
      end

      def channel_read
        @status = case @intent
        when :r
          if @channel.any?
            :ready
          else
            :idle
          end
        when :w
          :ready
        end
      end

      # [public]
      #
      def <<(message)
        @channel << message
      end

      # [public]
      #
      def read
        @channel.read
      end
    end
  end
end
