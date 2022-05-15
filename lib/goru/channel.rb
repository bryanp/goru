# frozen_string_literal: true

module Goru
  class Channel
    def initialize(size: nil)
      @size = size
      @messages = []
    end

    # [public]
    #
    def <<(message)
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
    def full?
      @size && @messages.size == @size
    end
  end
end
