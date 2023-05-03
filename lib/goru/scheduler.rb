# frozen_string_literal: true

require "etc"
require "is/global"

require_relative "channel"
require_relative "io_event_loop"
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

      @stopped = false
      @routines = Thread::Queue.new
      @coordinator = Thread::Queue.new

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

      @io_event_loop = IOEventLoop.new
      @threads << Thread.new {
        @io_event_loop.run
      }
    end

    # [public]
    #
    def go(state = nil, io: nil, channel: nil, intent: nil, &block)
      raise ArgumentError, "cannot set both `io` and `channel`" if io && channel

      routine = if io
        Routines::IO.new(state, io: io, intent: intent, event_loop: @io_event_loop, &block)
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
      @reactors.each(&:wakeup)

      routine
    end

    # [public]
    #
    def wait
      until @stopped
        @coordinator.pop
      end
    rescue Interrupt
    ensure
      stop
    end

    # [public]
    #
    def stop
      @stopped = true
      @routines.close
      @io_event_loop.stop
      @reactors.each(&:stop)
      @threads.each(&:join)
    end

    # [public]
    #
    def signal
      if @reactors.all?(&:finished?)
        @stopped = true
      end

      wakeup
    end

    def wakeup
      @coordinator << :wakeup
    end
  end
end
