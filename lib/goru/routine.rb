# frozen_string_literal: true

module Goru
  # [public]
  #
  class Routine
    def initialize(state = nil, &block)
      @state = state
      @block = block
      @status = :ready
      @result, @error, @reactor = nil
    end

    # [public]
    #
    attr_reader :state, :status

    # [public]
    #
    attr_writer :reactor

    # [public]
    #
    def call
      @block.call(self)
    rescue => error
      # TODO: Use `Is::Handler`.
      #
      puts "[routine error] #{error}"
      puts error.backtrace

      @error = error
      @status = :errored
    end

    # [public]
    #
    def finished(result = nil)
      unless @finished
        @result = result
        @status = :finished
      end
    end

    # [public]
    #
    def update(state)
      @state = state
    end

    # [public]
    #
    def result
      case @status
      when :errored
        raise @error
      else
        @result
      end
    end

    # [public]
    #
    def sleep(seconds)
      @status = :idle
      @reactor.sleep(self, seconds)
    end

    # [public]
    #
    def wake
      @status = :ready
    end
  end
end
