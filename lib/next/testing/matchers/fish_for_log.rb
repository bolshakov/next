# frozen_string_literal: true

module Next
  module Testing
    module Matchers
      class FishForLog < Base
        LEVELS = {info: Logger::Info, debug: Logger::Debug, warn: Logger::Warn, error: Logger::Error, fatal: Logger::Fatal}
        private_constant :LEVELS

        attr_reader :expected_message
        attr_reader :timeout
        attr_reader :actual_messages
        attr_reader :actual_message
        attr_reader :level
        attr_reader :human_readable_level

        def initialize(expected_message, level: nil, timeout: DEFAULT_TIMEOUT)
          @human_readable_level = (level || "any").to_s
          @level = Fear.option(level).map { LEVELS.fetch(_1) }.get_or_else(Logger::LogEvent)
          @expected_message = expected_message
          @timeout = timeout
          @actual_messages = []
        end

        def matches?(jailbreak:)
          deadline = Time.now + timeout

          loop do
            remaining_timeout = deadline - Time.now
            remaining_timeout = 0 if remaining_timeout < 0
            case receive_one(jailbreak:, timeout: remaining_timeout)
            in Fear::Some(actual_log_event)
              if fuzzy_matched?(expected_message, actual_log_event.message) && actual_log_event.is_a?(level)
                @actual_message = actual_log_event
                return true
              else
                actual_messages << actual_log_event
                next
              end
            in Fear::None
              return false
            end
          end
        end

        def failure_message
          "timeout (#{timeout}) while waiting for log level=#{human_readable_level} message=#{formatted_expected}.#{formatted_actual}"
        end

        private def formatted_expected
          RSpec::Support::ObjectFormatter.format(expected_message)
        end

        private def formatted_actual
          if actual_messages.any?
            actual_messages.reduce("\nReceived logs:") do |acc, msg|
              acc + "\n  * #{RSpec::Support::ObjectFormatter.format(msg)}"
            end
          else
            ""
          end
        end
      end
    end
  end
end
