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
      @status = nil
      @stopped = false
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

        if @queue.any? && (routine = @queue.pop(true))
          adopt_routine(routine)
        end

        interval = @timers.wait_interval

        if interval.nil?
          if @routines.empty?
            if @selector.empty?
              @status = :looking
              @scheduler.signal(self)
              if (routine = @queue.pop)
                adopt_routine(routine)
              end
            else
              # TODO: The issue doing this is that this reactor won't grab new routines. Will calling `@selector.wakeup`
              # from the scheduler when a routine is added to the queue resolve this?
              #
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
    ensure
      @selector.close
      @status = :finished
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
      routine.reactor = self

      case routine
      when Routines::IO
        monitor = @selector.register(routine.io, routine.intent)

        monitor.value = proc {
          # TODO: Try to combine this with `call_routine` below.
          #
          case routine.status
          when :selecting
            routine.call
          else
            @finished << routine
          end
        }
      else
        @routines << routine
      end
    end

    private def call_routine(routine)
      case routine.status
      when :running
        routine.call
      when :sleeping, :selecting
        # ignore these
      else
        @finished << routine
      end
    end

    private def cleanup_finished_routines
      until @finished.empty?
        routine = @finished.pop
        @routines.delete(routine)

        case routine
        when Routines::IO
          @selector.deregister(routine.io)
        end
      end
    end
  end
end
