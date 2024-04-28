# frozen_string_literal: true

module Next
  class Logger < Actor
    class Error < LogEvent
      def initialize(message:, progname: nil)
        super(message:, progname:, level: ::Logger::ERROR)
      end
    end
  end
end
