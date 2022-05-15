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
      @routines = []
      @finished = []
      @timers = Timers::Group.new
      @selector = NIO::Selector.new
      @stopped = false
      @status = nil
    end

    # [public]
    #
    attr_reader :status

    # [public]
    #
    def run
      @status = :running

      until @stopped
        @routines.each do |routine|
          call_routine(routine)
        end

        cleanup_finished_routines

        begin
          if (routine = @queue.pop(true))
            adopt_routine(routine)
          end
        rescue ThreadError => e
          interval = @timers.wait_interval

          if interval.nil?
            if @routines.empty?
              if @selector.empty?
                @status = :idle
                @scheduler.signal(self)
                if (routine = @queue.pop)
                  adopt_routine(routine)
                end
              else
                @selector.select do |monitor|
                  monitor.value.call
                end
              end
            else
              @selector.select(0) do |monitor|
                monitor.value.call
              end
            end
          elsif interval > 0
            if @selector.empty?
              Timers::Wait.for(interval) do |remaining|
                if (routine = @queue.pop_with_timeout(remaining))
                  adopt_routine(routine)
                  break
                end
              rescue ThreadError
                # nothing to do
              end
            else
              @selector.select(interval) do |monitor|
                monitor.value.call
              end
            end
          end

          @timers.fire
        end
      end
    ensure
      @selector.close
      @status = :finished
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
    def sleep(routine, seconds)
      @timers.after(seconds) {
        routine.wake
      }
    end

    private def adopt_routine(routine)
      case routine
      when Routines::IO
        routine.reactor = self
        @selector.register(routine.io, routine.intent).value = routine
      when Routine, Routines::Channel
        routine.reactor = self
        @routines << routine
      when :wakeup
        # ignore
      end
    end

    private def call_routine(routine)
      case routine.status
      when :idle
        # ignore
      when :ready
        routine.call
      else
        @finished << routine
      end
    end

    private def cleanup_finished_routines
      until @finished.empty?
        routine = @finished.pop

        case routine
        when Routines::IO
          @selector.deregister(routine.io)
        else
          @routines.delete(routine)
        end
      end
    end
  end
end
