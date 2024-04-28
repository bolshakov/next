# frozen_string_literal: true

module Next
  # Log listener subscribes to +Next::Logger::LogEvent+ events and
  # reports them to provided logger.
  #
  # @api private
  class Logger < Actor
    def self.props(logger:) = Props.new(self, logger:)

    attr_reader :logger

    def initialize(logger:)
      @logger = logger
    end

    def receive(event)
      case event
      in Logger::LogEvent(message:, progname:, level:)
        logger.add(level, message, progname)
      end
    end
  end
end
