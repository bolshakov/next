# frozen_string_literal: true

module Next
  class Logger < Actor
    class Info < LogEvent
      def initialize(message:, progname: nil)
        super(message:, progname:, level: ::Logger::INFO)
      end
    end
  end
end
