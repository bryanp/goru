# frozen_string_literal: true

require_relative "../channel"

module Goru
  module Routines
    module Channels
      # [public]
      #
      class Readable < Channel
        # [public]
        #
        def read
          @channel.read
        end

        private def update_status
          status = if @channel.any?
            Routine::STATUS_READY
          elsif @channel.closed?
            Routine::STATUS_FINISHED
          else
            Routine::STATUS_IDLE
          end

          set_status(status)
        end
      end
    end
  end
end
