# frozen_string_literal: true

module Next
  module Logging
    # This synchronous logging is used during the system
    # startup and shutdown because async logging might
    # be unavailable during this time.
    class SyncLog < Log
      attr_reader :logger

      def initialize(logger: ::Logger.new($stdout))
        @logger = logger
      end

      def info(message, progname = nil)
        add ::Logger::INFO, message, progname
      end

      def debug(message, progname = nil)
        add ::Logger::DEBUG, message, progname
      end

      def warn(message, progname = nil)
        add ::Logger::WARN, message, progname
      end

      def error(message, progname = nil)
        add ::Logger::ERROR, message, progname
      end

      def fatal(message, progname = nil)
        add ::Logger::FATAL, message, progname
      end

      private def add(level, message, progname)
        logger.add(level, message, progname)

        self
      end
    end
  end
end
