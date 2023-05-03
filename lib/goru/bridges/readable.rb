# frozen_string_literal: true

require_relative "../bridge"

module Goru
  module Bridges
    class Readable < Bridge
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
