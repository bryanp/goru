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
      @routines = []
      @ready = []
      @bridges = []
      @timers = Timers::Group.new
      @selector = NIO::Selector.new
      @stopped = false
      @status = nil
      @mutex = Mutex.new
    end

    # [public]
    #
    attr_reader :status

    # [public]
    #
    def run
      until @stopped
        set_status(:running)

        @ready.each do |routine|
          routine.call
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
              wait_for_bridge do
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

    private def wait_for_bridge
      # TODO: This approach is terribly slow, but is more accurate.
      #
      if @bridges.any? && @bridges.all? { |bridge| bridge.status == :idle }
        wait_for_routine
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
        if (routine = @queue.pop_with_timeout(timeout))
          adopt_routine(routine)
        end
      else
        if (routine = @queue.pop(!block))
          adopt_routine(routine)
        end
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
      @selector.wakeup
    end

    # [public]
    #
    def wakeup
      @selector.wakeup
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
      routine_not_ready(routine)
      @timers.after(seconds) {
        routine.wake
        routine_ready(routine)
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
        # TODO: Ideally we can combine everything into just a routine...
        #
        routine.reactor = self
        @bridges << routine
      when Routine
        routine.reactor = self
        @routines << routine
        if routine.status == :ready
          routine_ready(routine)
        end
      end
    end

    # [public]
    #
    def routine_finished(routine)
      case routine
      when Routines::Bridge
        @bridges.delete(routine)
      when Routines::IO
        @selector.deregister(routine.io)
      else
        routine_not_ready(routine)
        @routines.delete(routine)
      end
    end

    # [public]
    #
    def routine_errored(routine)
      routine_not_ready(routine)
    end

    private def routine_ready(routine)
      @ready << routine
    end

    private def routine_not_ready(routine)
      @ready.delete(routine)
    end

    private def set_status(status)
      @mutex.synchronize do
        @status = status
      end
    end
  end
end
