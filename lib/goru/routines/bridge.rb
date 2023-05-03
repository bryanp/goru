# frozen_string_literal: true

require_relative "channel"

module Goru
  module Routines
    # [public]
    #
    class Bridge < Channel
      def initialize(routine:, channel:)
        @routine = routine

        super(channel: channel)
      end

      # [public]
      #
      def ready?
        @status == :ready
      end

      # [public]
      #
      def call
        # noop
      end
    end
  end
end
