# frozen_string_literal: true

require "timers/group"
require "timers/wait"

require_relative "routines/io"

module Goru
  # [public]
  #
  class Reactor
    def initialize(queue:, scheduler:)
      @queue = queue
      @scheduler = scheduler
      @routines = Set.new
      @timers = Timers::Group.new
      @stopped = false
      @status = nil
      @coordinator = Thread::Queue.new
      @commands = []
    end

    # [public]
    #
    attr_reader :status

    # [public]
    #
    def run
      set_status(:running)

      until @stopped
        tick
      end
    ensure
      @timers.cancel
      @coordinator.close
      set_status(:finished)
    end

    private def tick
      # Apply queued commands.
      #
      while (command = @commands.shift)
        action, routine = command

        case action
        when :adopt
          routine.reactor = self
          @routines << routine
          routine.adopted
        when :cleanup
          @routines.delete(routine)
        end
      end

      # Call each ready routine.
      #
      @routines.each do |routine|
        routine.call if routine.ready?
      end

      # Adopt a new routine if available.
      #
      if (routine = @queue.pop(true))
        adopt_routine(routine)
      end
    rescue ThreadError
      interval = @timers.wait_interval

      if interval.nil? && @routines.empty?
        set_status(:idle)
        @scheduler.signal
        wait
        set_status(:running)
      elsif interval.nil?
        wait unless @routines.any?(&:ready?)
      elsif interval > 0
        Timers::Wait.for(interval) do |remaining|
          break if wait(timeout: remaining)
        end
      end

      @timers.fire
    end

    private def wait(timeout: nil)
      if timeout
        @coordinator.pop(timeout: timeout)
      else
        @coordinator.pop
      end
    end

    # [public]
    #
    def finished?
      @status == :idle || @status == :stopped
    end

    # [public]
    #
    def wakeup
      @coordinator << :wakeup
    rescue ClosedQueueError
    end

    # [public]
    #
    def stop
      @stopped = true
      wakeup
    rescue ClosedQueueError
      # nothing to do
    end

    # [public]
    #
    def asleep_for(seconds)
      @timers.after(seconds) {
        yield
      }
    end

    # [public]
    #
    def adopt_routine(routine)
      command(:adopt, routine)
    end

    # [public]
    #
    def routine_finished(routine)
      command(:cleanup, routine)
    end

    private def command(action, routine)
      @commands << [action, routine]
      wakeup
    end

    private def set_status(status)
      @status = status
    end
  end
end
