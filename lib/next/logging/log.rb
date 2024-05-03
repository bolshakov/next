# frozen_string_literal: true

module Next
  module Logging
    # Provides interface for asynchronous logging
    # @abstract
    class Log
      def info(message, progname = nil)
        raise NotImplementedError
      end

      def debug(message, progname = nil)
        raise NotImplementedError
      end

      def warn(message, progname = nil)
        raise NotImplementedError
      end

      def error(message, progname = nil)
        raise NotImplementedError
      end

      def fatal(message, progname = nil)
        raise NotImplementedError
      end
    end
  end
end
