# frozen_string_literal: true

module Next
  module Logging
    # Provides interface for asynchronous logging
    # @see System#log
    class Log
      attr_reader :event_stream
      private :event_stream

      def initialize(system)
        @event_stream = system.event_stream
      end

      def info(message, progname = nil)
        publish(Logger::Info.new(message:, progname:))
      end

      def debug(message, progname = nil)
        publish(Logger::Debug.new(message:, progname:))
      end

      def warn(message, progname = nil)
        publish(Logger::Warn.new(message:, progname:))
      end

      def error(message, progname = nil)
        publish(Logger::Error.new(message:, progname:))
      end

      def fatal(message, progname = nil)
        publish(Logger::Fatal.new(message:, progname:))
      end

      private def publish(...)
        event_stream.publish(...)

        self
      end
    end
  end
end
