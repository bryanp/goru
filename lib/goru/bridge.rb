# frozen_string_literal: true

module Goru
  # [public]
  #
  class Bridge
    def initialize(routine:, channel:)
      @routine = routine
      @channel = channel
      @channel.add_observer(self)
      update_status
    end

    # [public]
    #
    STATUS_READY = :ready

    # [public]
    #
    STATUS_FINISHED = :finished

    # [public]
    #
    STATUS_IDLE = :idle

    # [public]
    #
    attr_reader :status

    # [public]
    #
    private def set_status(status)
      @status = status
      status_changed
    end

    # [public]
    #
    def update_status
      # noop
    end

    private def status_changed
      case @status
      when :STATUS_READY
        @routine.bridged
      when :STATUS_FINISHED
        @channel.remove_observer(self)
        @routine.unbridge
      end
    end

    def channel_received
      update_status
    end

    def channel_read
      update_status
    end

    def channel_closed
      update_status
    end
  end
end
