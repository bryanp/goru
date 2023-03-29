# frozen_string_literal: true

require "etc"
require "is/global"

require_relative "channel"
require_relative "reactor"
require_relative "routines/channel"
require_relative "routines/io"

require_relative "routines/channels/readable"
require_relative "routines/channels/writable"

module Goru
  # [public]
  #
  class Scheduler
    include Is::Global
    include MonitorMixin

    class << self
      # Prevent issues when including `Goru` at the toplevel.
      #
      # [public]
      #
      def go(...)
        global.go(...)
      end

      # [public]
      #
      def default_scheduler_count
        Etc.nprocessors
      end
    end

    def initialize(count: self.class.default_scheduler_count)
      super()

      @stopping = false
      @routines = Thread::Queue.new
      @condition = new_cond

      @reactors = count.times.map {
        Reactor.new(queue: @routines, scheduler: self)
      }

      @threads = @reactors.map { |reactor|
        Thread.new {
          Thread.handle_interrupt(Interrupt => :never) do
            reactor.run
          end
        }
      }
    end

    # [public]
    #
    def go(state = nil, io: nil, channel: nil, intent: nil, &block)
      raise ArgumentError, "cannot set both `io` and `channel`" if io && channel

      routine = if io
        Routines::IO.new(state, io: io, intent: intent, &block)
      elsif channel
        case intent
        when :r
          Routines::Channels::Readable.new(state, channel: channel, &block)
        when :w
          Routines::Channels::Writable.new(state, channel: channel, &block)
        end
      else
        Routine.new(state, &block)
      end

      @routines << routine
      @reactors.each(&:signal)

      routine
    end

    # [public]
    #
    def wait
      synchronize do
        @condition.wait_until do
          @stopping
        end
      end
    rescue Interrupt
    ensure
      stop
    end

    # [public]
    #
    def stop
      @stopping = true
      @routines.close
      @reactors.each(&:stop)
      @threads.each(&:join)
    end

    # [public]
    #
    def signal(reactor)
      synchronize do
        if @reactors.all?(&:finished?)
          @stopping = true
        end

        @condition.signal
      end
    end
  end
end
