# frozen_string_literal: true

module Next
  class Logger < Actor
    class Fatal < LogEvent
      def initialize(message:, progname: nil)
        super(message:, progname:, level: ::Logger::FATAL)
      end
    end
  end
end
