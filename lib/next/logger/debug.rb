# frozen_string_literal: true

module Next
  class Logger < Actor
    class Debug < LogEvent
      def initialize(message:, progname: nil)
        super(message:, progname:, level: ::Logger::DEBUG)
      end
    end
  end
end
