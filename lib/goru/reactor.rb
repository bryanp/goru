# frozen_string_literal: true

require "nio"

require "timers/group"
require "timers/wait"

require_relative "routines/bridge"
require_relative "routines/io"

module Goru
  # [public]
  #
  class Reactor
    def initialize(queue:, scheduler:)
      @queue = queue
      @scheduler = scheduler
      @routines = Set.new
      @bridges = Set.new
      @timers = Timers::Group.new
      @selector = NIO::Selector.new
      @stopped = false
      @status = nil
      @mutex = Mutex.new
      @cleanup = {
        bridges: [],
        monitors: [],
        routines: []
      }
    end

    # [public]
    #
    attr_reader :status

    # [public]
    #
    def run
      until @stopped
        set_status(:running)

        cleanup

        @routines.each do |routine|
          call_routine(routine)
        end

        begin
          wait_for_routine(block: false)
        rescue ThreadError
          interval = @timers.wait_interval

          if interval.nil?
            if @routines.empty?
              if @selector.empty?
                become_idle
              else
                wait_for_bridge do
                  wait_for_selector
                end
              end
            else
              wait_for_bridge do
                wait_for_selector(0)
              end
            end
          elsif interval > 0
            if @selector.empty?
              wait_for_interval(interval)
            else
              wait_for_bridge(interval) do
                wait_for_selector(interval)
              end
            end
          end

          @timers.fire
        end
      end
    ensure
      @selector.close
      set_status(:finished)
    end

    private def cleanup
      while (routine = @cleanup[:bridges].shift)
        @bridges.delete(routine)
      end

      while (routine = @cleanup[:monitors].shift)
        routine.monitor.close
      end

      while (routine = @cleanup[:routines].shift)
        @routines.delete(routine)
      end
    end

    private def become_idle
      set_status(:idle)
      @scheduler.signal(self)
      wait_for_routine
    end

    private def wait_for_selector(timeout = nil)
      @selector.select(timeout) do |monitor|
        monitor.value.call
      end
    end

    private def wait_for_bridge(interval = nil)
      if @bridges.any?(&:applicable?) && @bridges.none?(&:ready?)
        if interval.nil?
          wait_for_routine
        elsif interval > 0
          wait_for_interval(interval)
        end
      else
        yield
      end
    end

    private def wait_for_interval(timeout)
      Timers::Wait.for(timeout) do |remaining|
        break if wait_for_routine(timeout: remaining)
      rescue ThreadError
        # nothing to do
      end
    end

    private def wait_for_routine(block: true, timeout: nil)
      if timeout
        if (routine = @queue.pop(timeout: timeout))
          adopt_routine(routine)
        end
      elsif (routine = @queue.pop(!block))
        adopt_routine(routine)
      end
    end

    # [public]
    #
    def finished?
      @mutex.synchronize do
        @status == :idle || @status == :stopped
      end
    end

    # [public]
    #
    def signal
      unless @selector.empty?
        @selector.wakeup
      end
    end

    # [public]
    #
    def wakeup
      signal
      @queue << :wakeup
    end

    # [public]
    #
    def stop
      @stopped = true
      @selector.wakeup
    rescue IOError
    end

    # [public]
    #
    def routine_asleep(routine, seconds)
      @timers.after(seconds) {
        routine.wake
      }
    end

    # [public]
    #
    def adopt_routine(routine)
      case routine
      when Routines::IO
        monitor = @selector.register(routine.io, routine.intent)
        monitor.value = routine
        routine.monitor = monitor
        routine.reactor = self
      when Routines::Bridge
        routine.reactor = self
        @bridges << routine
      when Routine
        routine.reactor = self
        @routines << routine
      end
    end

    # [public]
    #
    def routine_finished(routine)
      cleanup_key = case routine
      when Routines::Bridge
        :bridges
      when Routines::IO
        :monitors
      else
        :routines
      end

      @cleanup[cleanup_key] << routine
      signal
    end

    private def set_status(status)
      @mutex.synchronize do
        @status = status
      end
    end

    private def call_routine(routine)
      case routine.status
      when :ready
        routine.call
      end
    end
  end
end
