# frozen_string_literal: true

require "set"

module Goru
  class Channel
    def initialize(size: nil)
      @size = size
      @messages = []
      @closed = false
      @observers = Set.new
    end

    # [public]
    #
    attr_writer :observer

    # [public]
    #
    def <<(message)
      raise "closed" if @closed
      @messages << message
      @observers.each(&:channel_received)
    end

    # [public]
    #
    def read
      message = @messages.shift
      @observers.each(&:channel_read)
      message
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
      @observers.each(&:channel_closed)
    end

    # [public]
    #
    def reopen
      @closed = false
      @observers.each(&:channel_reopened)
    end

    # [public]
    #
    def clear
      @messages.clear
    end

    # [public]
    #
    def length
      @messages.length
    end

    # [public]
    #
    def add_observer(observer)
      @observers << observer
    end

    # [public]
    #
    def remove_observer(observer)
      @observers.delete(observer)
    end
  end
end
