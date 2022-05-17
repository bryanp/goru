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
      set_status(:ready)
      @result, @error, @reactor = nil
    end

    # [public]
    #
    attr_reader :state, :status

    # [public]
    #
    def reactor=(reactor)
      @reactor = reactor
      status_changed
    end

    # [public]
    #
    def call
      @block.call(self)
    rescue => error
      @error = error
      set_status(:errored)
      trigger(error)
    end

    # [public]
    #
    def finished(result = nil)
      unless @finished
        @result = result
        set_status(:finished)
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
      set_status(:idle)
      @reactor.routine_asleep(self, seconds)
    end

    # [public]
    #
    def wake
      set_status(:ready)
    end

    # [public]
    #
    private def set_status(status)
      @status = status
      status_changed
    end

    # [public]
    #
    private def status_changed
      case @status
      when :finished
        @reactor&.routine_finished(self)
      end
    end
  end
end
