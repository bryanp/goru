# frozen_string_literal: true

require_relative "../channel"

module Goru
  module Routines
    module Channels
      # [public]
      #
      class Writable < Channel
        # [public]
        #
        def <<(message)
          @channel << message
        end

        private def update_status
          status = if @channel.full?
            Routine::STATUS_IDLE
          elsif @channel.closed?
            Routine::STATUS_FINISHED
          else
            Routine::STATUS_READY
          end

          set_status(status)
        end
      end
    end
  end
end
