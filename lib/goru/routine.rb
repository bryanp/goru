# frozen_string_literal: true

require "is/handler"

module Goru
  # [public]
  #
  class Routine
    include Is::Handler

    # TODO: This should essentially be an "unhandled" handler. Probably needs to be introduced into corerb.
    #
    handle(StandardError) do |event:|
      $stderr << <<~ERROR
        [goru] routine crashed: #{event}
        #{event.backtrace.join("\n")}
      ERROR
    end

    def initialize(state = nil, &block)
      @state = state
      @block = block
      @status = :ready
      @result, @error, @reactor = nil
    end

    # [public]
    #
    attr_reader :state, :status

    # [public]
    #
    attr_writer :reactor

    # [public]
    #
    def call
      @block.call(self)
    rescue => error
      @error = error
      @status = :errored
      trigger(error)
    end

    # [public]
    #
    def finished(result = nil)
      unless @finished
        @result = result
        @status = :finished
        @reactor.cleanup_routine(self)
      end
    end

    # [public]
    #
    def update(state)
      @state = state
    end

    # [public]
    #
    def result
      case @status
      when :errored
        raise @error
      else
        @result
      end
    end

    # [public]
    #
    def sleep(seconds)
      @status = :idle
      @reactor.sleep(self, seconds)
    end

    # [public]
    #
    def wake
      @status = :ready
    end
  end
end
