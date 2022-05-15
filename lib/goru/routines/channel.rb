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
        @intent = intent
        @status = :dynamic
      end

      # [public]
      #
      def <<(message)
        @channel << message
        @reactor&.wakeup
      end

      # [public]
      #
      def read
        @channel.read
      end

      # [public]
      #
      def status
        case @status
        when :dynamic
          determine_status
        else
          @status
        end
      end

      private def determine_status
        case @intent
        when :r
          if @channel.any?
            :ready
          else
            :idle
          end
        when :w
          if @channel.full?
            :idle
          else
            :ready
          end
        end
      end
    end
  end
end
