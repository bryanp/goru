# frozen_string_literal: true

require_relative "../bridge"

module Goru
  module Bridges
    class Writable < Bridge
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
