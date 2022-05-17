# frozen_string_literal: true

require_relative "../channel"

module Goru
  module Routines
    module Channels
      # [public]
      #
      class Readable < Channel
        def initialize(...)
          super

          update_status
        end

        # [public]
        #
        def read
          @channel.read
        end

        private def update_status
          status = if @channel.any?
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
