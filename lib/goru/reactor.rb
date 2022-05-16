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
      @bridges = []
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

        begin
          if (routine = @queue.pop(true))
            adopt_routine(routine)
          end
        rescue ThreadError
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
                if @bridges.any? { |bridge| bridge.status == :idle }
                  if (routine = @queue.pop)
                    adopt_routine(routine)
                  end
                else
                  @selector.select do |monitor|
                    monitor.value.call
                  end
                end
              end
            else
              if @bridges.any? { |bridge| bridge.status == :idle }
                if (routine = @queue.pop)
                  adopt_routine(routine)
                end
              else
                @selector.select(0) do |monitor|
                  monitor.value.call
                end
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
              # TODO: See notes about bridge above. Anytime we're selecting, we first need to check if there are bridges
              # waiting for data (whose selectors may actually be unblocked).
              #
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
      when Routine, Routines::Channel
        routine.reactor = self
        @routines << routine
      end
    end

    # [public]
    #
    def cleanup_routine(routine)
      case routine
      when Routines::Bridge
        @bridges.delete(routine)
      when Routines::IO
        @selector.deregister(routine.io)
      else
        @routines.delete(routine)
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
