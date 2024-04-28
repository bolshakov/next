# frozen_string_literal: true

module Next
  class Logger < Actor
    class Warn < LogEvent
      def initialize(message:, progname: nil)
        super(message:, progname:, level: ::Logger::WARN)
      end
    end
  end
end
