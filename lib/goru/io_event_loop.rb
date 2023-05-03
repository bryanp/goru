# frozen_string_literal: true

require "nio"

module Goru
  # [public]
  #
  class IOEventLoop
    def initialize
      @commands = []
      @selector = NIO::Selector.new
      @stopped = false
    end

    # [public]
    #
    def run
      until @stopped
        while (command = @commands.shift)
          action, routine = command

          case action
          when :register
            monitor = @selector.register(routine.io, routine.intent)
            monitor.value = routine.method(:wakeup)
            routine.monitor = monitor
          when :deregister
            routine.monitor = nil
            routine.monitor&.close
          end
        end

        @selector.select do |monitor|
          monitor.value.call
        end
      end
    ensure
      @selector.close
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
    def <<(tuple)
      @commands << tuple
      @selector.wakeup
    end
  end
end
