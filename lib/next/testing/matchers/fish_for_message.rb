# frozen_string_literal: true

module Next
  module Testing
    module Matchers
      class FishForMessage < Base
        attr_reader :expected_message
        attr_reader :timeout
        attr_reader :actual_messages
        attr_reader :actual_message

        def initialize(expected_message, timeout: DEFAULT_TIMEOUT)
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
            in Fear::Some(actual_message)
              if fuzzy_matched?(expected_message, actual_message)
                @actual_message = actual_message
                return true
              else
                actual_messages << actual_message
                next
              end
            in Fear::None
              return false
            end
          end
        end

        def failure_message
          "timeout (#{timeout}) during fish_for_message while fishing for #{formatted_expected}.#{formatted_actual}"
        end

        private def formatted_expected
          RSpec::Support::ObjectFormatter.format(expected_message)
        end

        private def formatted_actual
          if actual_messages.any?
            actual_messages.reduce("\nReceived messages:") do |acc, msg|
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
