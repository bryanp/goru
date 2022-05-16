# frozen_string_literal: true

require "is/global"

require_relative "channel"
require_relative "queue"
require_relative "reactor"
require_relative "routines/channel"
require_relative "routines/io"

module Goru
  # [public]
  #
  class Scheduler
    include Is::Global
    include MonitorMixin

    def initialize(...)
      super

      @stopping = false
      @routines = Queue.new
      @condition = new_cond

      # TODO: Base this on the number of cpus?
      #
      @reactors = 10.times.map {
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

    INTENTS = %i[r w].freeze

    # [public]
    #
    def go(state = nil, io: nil, channel: nil, intent: nil, &block)
      intent = intent&.to_sym
      raise ArgumentError, "cannot set both `io` and `channel`" if io && channel
      raise ArgumentError, "unknown intent: #{intent}" if intent && !INTENTS.include?(intent)

      @routines << if io
        Routines::IO.new(state, io: io, intent: intent, &block)
      elsif channel
        Routines::Channel.new(state, channel: channel, intent: intent, &block)
      else
        Routine.new(state, &block)
      end

      @reactors.each(&:signal)
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
