# frozen_string_literal: true

module Goru
  # [public] Based on: https://spin.atomicobject.com/2017/06/28/queue-pop-with-timeout-fixed/
  #
  class Queue
    def initialize
      @mutex = Mutex.new
      @queue = []
      @received = ConditionVariable.new
      @closed = false
    end

    # [public]
    #
    def <<(x)
      @mutex.synchronize do
        @queue << x
        @received.signal
      end
    end

    # [public]
    #
    def pop(non_block = false)
      pop_with_timeout(non_block ? 0 : nil)
    end

    # [public]
    #
    def pop_with_timeout(timeout = nil)
      @mutex.synchronize do
        if timeout.nil?
          # wait indefinitely until there is an element in the queue
          while @queue.empty? && !@closed
            @received.wait(@mutex)
          end
        elsif @queue.empty? && !@closed && timeout != 0
          # wait for element or timeout
          timeout_time = timeout + Time.now.to_f
          while @queue.empty? && (remaining_time = timeout_time - Time.now.to_f) > 0
            @received.wait(@mutex, remaining_time)
          end
        end
        return if @closed
        # if we're still empty after the timeout, raise exception
        raise ThreadError, "queue empty" if @queue.empty?
        @queue.shift
      end
    end

    # [public]
    #
    def close
      @mutex.synchronize do
        @closed = true
        @received.broadcast
      end
    end

    # [public]
    #
    def any?
      !@queue.empty?
    end
  end
end
