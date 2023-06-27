# frozen_string_literal: true

require_relative "../routine"
require_relative "../bridges/readable"
require_relative "../bridges/writable"

module Goru
  module Routines
    # [public]
    #
    class IO < Routine
      def initialize(state = nil, io:, intent:, event_loop:, &block)
        super(state, &block)

        @io = io
        @intent = normalize_intent(intent)
        @event_loop = event_loop
        @status = :orphaned
        @monitor = nil
      end

      # [public]
      #
      attr_reader :io, :intent

      attr_accessor :monitor

      # [public]
      #
      def adopted
        set_status(:ready)
      end

      # [public]
      #
      def wakeup
        # Keep this io from being selected again until the underlying routine is called.
        # Interests are reset in `#call`.
        #
        @monitor&.interests = nil

        set_status(:io_ready)
      end

      READY_STATUSES = [:io_ready, :ready].freeze
      READY_BRIDGE_STATUSES = [nil, :ready].freeze

      # [public]
      #
      def ready?
        READY_STATUSES.include?(@status) && READY_BRIDGE_STATUSES.include?(@bridge&.status)
      end

      def call
        super

        @monitor&.interests = @intent
      end

      # [public]
      #
      def accept
        @io.accept_nonblock
      rescue Errno::EAGAIN
        wait
      rescue Errno::ECONNRESET, Errno::EPIPE, EOFError
        finished
        nil
      end

      def wait
        set_status(:selecting)
        @reactor.register(self) unless @monitor

        throw :continue
      end

      # [public]
      #
      def read(bytes)
        @io.read_nonblock(bytes)
      rescue Errno::EAGAIN
        wait
      rescue Errno::ECONNRESET, Errno::EPIPE, EOFError
        finished
        nil
      end

      # [public]
      #
      def write(data)
        @io.write_nonblock(data)
      rescue Errno::EAGAIN
        wait
      rescue Errno::ECONNRESET, Errno::EPIPE, EOFError
        finished
        nil
      end

      # [public]
      #
      def intent=(intent)
        intent = normalize_intent(intent)
        validate_intent!(intent)

        @monitor&.interests = intent
        @intent = intent
      end

      # [public]
      #
      def bridge(state = nil, intent:, channel:, &block)
        raise "routine is already bridged" if @bridge

        intent = normalize_intent(intent)
        validate_intent!(intent)
        self.intent = intent

        @bridge = case intent
        when :r
          Bridges::Readable.new(routine: self, channel: channel)
        when :w
          Bridges::Writable.new(routine: self, channel: channel)
        end

        routine = case intent
        when :r
          Routines::Channels::Readable.new(state, channel: channel, &block)
        when :w
          Routines::Channels::Writable.new(state, channel: channel, &block)
        end

        @reactor.adopt_routine(routine)
        @reactor.wakeup

        routine
      end

      # [public]
      #
      def bridged
        @reactor.wakeup
      end

      # [public]
      #
      def unbridge
        @bridge = nil
        @reactor.wakeup
      end

      private def status_changed
        case @status
        when :finished
          @reactor&.deregister(self)
        end

        super
      end

      INTENTS = %i[r w].freeze

      private def validate_intent!(intent)
        raise ArgumentError, "unknown intent: #{intent}" unless INTENTS.include?(intent)
      end

      private def normalize_intent(intent)
        intent.to_sym
      end
    end
  end
end
