# frozen_string_literal: true

require_relative "../bridge"

module Goru
  module Routines
    module Bridges
      class Writable < Bridge
        # [public]
        #
        def applicable?
          @routine.intent == :w
        end

        private def update_status
          status = if @routine.status == :finished
            :finished
          elsif @channel.any?
            :ready
          elsif @channel.closed?
            :finished
          else
            :idle
          end

          set_status(status)
        end
      end
    end
  end
end
