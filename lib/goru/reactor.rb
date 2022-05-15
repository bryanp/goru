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
          adopt_routine(@queue.pop(true))
        rescue ThreadError
        end

        interval = @timers.wait_interval

        if interval.nil?
          if @routines.empty? && @selector.empty? && @queue.empty?
            @status = :looking
            @scheduler.signal(self)
          else
            @status = :running
          end

          if @routines.empty? && @queue.empty?
            @selector.select do |monitor|
              call_routine(monitor.value)
            end
          elsif !@selector.empty?
            @selector.select(0) do |monitor|
              call_routine(monitor.value)
            end
          end
        elsif interval > 0
          @selector.select(interval) do |monitor|
            call_routine(monitor.value)
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
    def signal
      @selector.wakeup
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
        @selector.register(routine.io, routine.intent).value = routine
      else
        @routines << routine
      end
    end

    private def call_routine(routine)
      case routine.status
      when :running, :selecting
        routine.call
      when :sleeping
        # ignore
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
