# frozen_string_literal: true

module Next
  class Logger < Actor
    class Unknown < LogEvent
      def initialize(message:, progname: nil)
        super(message:, progname:, level: ::Logger::UNKNOWN)
      end
    end
  end
end
