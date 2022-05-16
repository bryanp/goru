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
        @status = :dynamic
      end

      # [public]
      #
      def status
        case @status
        when :dynamic
          status = determine_status
          finished if status == :finished
          status
        else
          @status
        end
      end

      private def determine_status
        if @routine.status == :finished
          :finished
        else
          case @routine.intent
          when :r
            if @channel.closed?
              :finished
            elsif @channel.full?
              :idle
            else
              :ready
            end
          when :w
            if @channel.any?
              :ready
            elsif @channel.closed?
              :finished
            else
              :idle
            end
          end
        end
      end
    end
  end
end
