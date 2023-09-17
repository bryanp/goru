# frozen_string_literal: true

require "etc"
require "nio"
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
      def default_reactor_count
        Etc.nprocessors
      end
    end

    def initialize(count: self.class.default_reactor_count)
      super()

      @waiting = false
      @stopped = false
      @routines = Thread::Queue.new
      @selector = NIO::Selector.new

      @reactors = count.times.map {
        Reactor.new(queue: @routines, scheduler: self)
      }

      @threads = @reactors.map { |reactor|
        Thread.new {
          Thread.handle_interrupt(Interrupt => :never) do
            reactor.run
          rescue IOError
          end
        }
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
      @waiting = true
      @reactors.each(&:wakeup)
      @selector.select while @waiting
    rescue IOError, Interrupt
      # nothing to do
    ensure
      stop
    end

    # [public]
    #
    def stop
      @stopped = true
      @routines.close
      @selector.close
      @reactors.each(&:stop)
      @threads.each(&:join)
    end

    # [public]
    #
    def signal
      return unless @waiting && @reactors.all?(&:finished?)
      @waiting = false
      wakeup
    end

    def wakeup
      @selector.wakeup
    rescue IOError
      # nothing to do
    end
  end
end
