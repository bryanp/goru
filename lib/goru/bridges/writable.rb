# frozen_string_literal: true

require_relative "../bridge"

module Goru
  module Bridges
    class Writable < Bridge
      private def update_status
        status = if @routine.status == Routine::STATUS_FINISHED
          Bridge::STATUS_FINISHED
        elsif @channel.any?
          Bridge::STATUS_READY
        elsif @channel.closed?
          Bridge::STATUS_FINISHED
        else
          Bridge::STATUS_IDLE
        end

        set_status(status)
      end
    end
  end
end
