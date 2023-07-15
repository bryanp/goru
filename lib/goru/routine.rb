# frozen_string_literal: true

require "is/handler"

module Goru
  # [public]
  #
  class Routine
    include Is::Handler

    handle(StandardError) do |event:|
      if @debug
        $stderr << <<~ERROR
          [goru] routine crashed: #{event}
          #{event.backtrace.join("\n")}
        ERROR
      end
    end

    def initialize(state = nil, &block)
      @state = state
      @block = block
      set_status(:ready)
      @result, @error, @reactor = nil
      @debug = true
    end

    # [public]
    #
    attr_reader :state, :status, :error

    # [public]
    #
    attr_writer :debug

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
      @result = result
      set_status(:finished)

      throw :continue
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
      @reactor.asleep_for(seconds) do
        set_status(:ready)
      end

      throw :continue
    end

    # [public]
    #
    def ready?
      @status == :ready
    end

    # [public]
    #
    def pause
      set_status(:paused)
    end

    # [public]
    #
    def resume
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
      when :errored, :finished
        @reactor&.routine_finished(self)
      end
    end

    # [public]
    #
    def adopted
      # noop
    end
  end
end
