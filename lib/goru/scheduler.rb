# frozen_string_literal: true

require "is/global"

require_relative "queue"
require_relative "reactor"
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

    # [public]
    #
    def go(state = nil, io: nil, intent: :rw, &block)
      @routines << if io
        Routines::IO.new(state, io: io, intent: intent, &block)
      else
        Routine.new(state, &block)
      end
    end

    # [public]
    #
    def wait
      synchronize do
        @condition.wait_until do
          @stopping
        end
      end
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
        if @reactors.all? { |reactor| reactor.status == :looking || reactor.status == :stopped }
          @stopping = true
        end

        @condition.signal
      end
    end
  end
end
