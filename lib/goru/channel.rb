# frozen_string_literal: true

module Goru
  class Channel
    def initialize(size: nil)
      @size = size
      @messages = []
      @closed = false
      @observer = nil
    end

    # [public]
    #
    attr_writer :observer

    # [public]
    #
    def <<(message)
      raise "closed" if @closed
      @messages << message
      @observer&.channel_received
    end

    # [public]
    #
    def read
      @messages.shift
      @observer&.channel_read
    end

    # [public]
    #
    def any?
      @messages.any?
    end

    # [public]
    #
    def empty?
      @messages.empty?
    end

    # [public]
    #
    def full?
      @size && @messages.size == @size
    end

    # [public]
    #
    def closed?
      @closed == true
    end

    # [public]
    #
    def close
      @closed = true
    end
  end
end
