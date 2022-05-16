# frozen_string_literal: true

module Goru
  class Channel
    def initialize(size: nil)
      @size = size
      @messages = []
      @closed = false
    end

    # [public]
    #
    def <<(message)
      raise "closed" if @closed
      @messages << message
    end

    # [public]
    #
    def read
      @messages.shift
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
