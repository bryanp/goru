# frozen_string_literal: true

require "nio"
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
      @selector = NIO::Selector.new
      @commands = []
    end

    # [public]
    #
    STATUS_RUNNING = :running

    # [public]
    #
    STATUS_FINISHED = :finished

    # [public]
    #
    STATUS_IDLE = :idle

    # [public]
    #
    STATUS_STOPPED = :stopped

    # [public]
    #
    attr_reader :status

    # [public]
    #
    def run
      set_status(STATUS_RUNNING)

      until @stopped
        tick
      end
    ensure
      @timers.cancel
      @selector.close
      set_status(STATUS_FINISHED)
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
        when :register
          monitor = @selector.register(routine.io, routine.intent)
          monitor.value = routine.method(:wakeup)
          routine.monitor = monitor
        when :deregister
          routine.monitor&.close
          routine.monitor = nil
        end
      end

      # Call each ready routine.
      #
      @routines.each do |routine|
        next unless routine.ready?

        catch :continue do
          routine.call
        end
      end

      # Adopt a new routine if available.
      #
      if (routine = @queue.pop(true))
        adopt_routine(routine)
      end
    rescue ThreadError
      interval = @timers.wait_interval

      if interval.nil? && @routines.empty?
        set_status(STATUS_IDLE)
        @scheduler.signal
        wait
        set_status(STATUS_RUNNING)
      elsif interval.nil?
        wait unless @routines.any?(&:ready?)
      elsif interval > 0
        wait(timeout: interval)
      end

      @timers.fire
    rescue IOError
    end

    private def wait(timeout: nil)
      @selector.select(timeout) do |monitor|
        monitor.value.call
      end
    end

    # [public]
    #
    def finished?
      @status == STATUS_IDLE || @status == STATUS_STOPPED
    end

    # [public]
    #
    def wakeup
      @selector.wakeup
    rescue IOError
      # nothing to do
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

    # [public]
    #
    def register(routine)
      command(:register, routine)
    end

    # [public]
    #
    def deregister(routine)
      command(:deregister, routine)
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
