# frozen_string_literal: true

require_relative "../bridge"

module Goru
  module Bridges
    class Readable < Bridge
      private def update_status
        status = if @routine.status == Routine::STATUS_FINISHED
          Bridge::STATUS_FINISHED
        elsif @channel.full?
          Bridge::STATUS_IDLE
        elsif @channel.closed?
          Bridge::STATUS_FINISHED
        else
          Bridge::STATUS_READY
        end

        set_status(status)
      end
    end
  end
end
