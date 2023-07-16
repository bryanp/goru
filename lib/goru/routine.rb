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
      @observers = Set.new
      set_status(STATUS_READY)
      @result, @error, @reactor = nil
      @debug = true
    end

    # [public]
    #
    STATUS_READY = :ready

    # [public]
    #
    STATUS_FINISHED = :finished

    # [public]
    #
    STATUS_ERRORED = :errored

    # [public]
    #
    STATUS_IDLE = :idle

    # [public]
    #
    STATUS_PAUSED = :paused

    # [public]
    #
    attr_reader :state, :status, :error, :reactor

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
      set_status(STATUS_ERRORED)
      trigger(error)
    end

    # [public]
    #
    def finished(result = nil)
      @result = result
      set_status(STATUS_FINISHED)

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
      when STATUS_ERRORED
        raise @error
      else
        @result
      end
    end

    # [public]
    #
    def sleep(seconds)
      set_status(STATUS_IDLE)
      @reactor.asleep_for(seconds) do
        set_status(STATUS_READY)
      end

      throw :continue
    end

    # [public]
    #
    def ready?
      @status == STATUS_READY
    end

    # [public]
    #
    def finished?
      @status == STATUS_ERRORED || @status == STATUS_FINISHED
    end

    # [public]
    #
    def pause
      set_status(STATUS_PAUSED)
    end

    # [public]
    #
    def resume
      set_status(STATUS_READY)
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
      @observers.each(&:call)

      case @status
      when STATUS_ERRORED, STATUS_FINISHED
        @reactor&.routine_finished(self)
      end
    end

    # [public]
    #
    def adopted
      # noop
    end

    # [public]
    #
    def add_observer(observer = nil, &block)
      @observers << (block || observer.method(:routine_status_changed))
    end

    # [public]
    #
    def remove_observer(observer)
      @observers.delete(observer)
    end
  end
end
