# frozen_string_literal: true

module Next
  module Logging
    # This synchronous logging is used during the system
    # startup and shutdown because async logging might
    # be unavailable during this time.
    class SyncLog < Log
      attr_reader :logger

      LEVELS = {
        info: ::Logger::INFO,
        debug: ::Logger::DEBUG,
        warn: ::Logger::WARN,
        error: ::Logger::ERROR,
        fatal: ::Logger::FATAL,
        unknown: ::Logger::UNKNOWN
      }.freeze
      private_constant :LEVELS

      def self.level(name) = LEVELS.fetch(name.to_sym) do
        raise ArgumentError, "log level is not supported #{name}"
      end

      def initialize(logger)
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
