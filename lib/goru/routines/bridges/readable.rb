# frozen_string_literal: true

require_relative "../bridge"

module Goru
  module Routines
    module Bridges
      class Readable < Bridge
        def initialize(...)
          super

          update_status
        end

        # [public]
        #
        def applicable?
          @routine.intent == :r
        end

        private def update_status
          status = if @routine.status == :finished
            :finished
          elsif @channel.full?
            :idle
          elsif @channel.closed?
            :finished
          else
            :ready
          end

          set_status(status)
        end
      end
    end
  end
end
