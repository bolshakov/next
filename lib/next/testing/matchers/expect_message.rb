# frozen_string_literal: true

module Next
  module Testing
    module Matchers
      class ExpectMessage < Base
        attr_reader :expected_message
        attr_reader :actual_message
        attr_reader :timeout

        def initialize(expected_message, timeout: DEFAULT_TIMEOUT)
          @expected_message = expected_message
          @timeout = timeout
        end

        def matches?(jailbreak:)
          @actual_message = receive_one(jailbreak:, timeout:)

          case [expected_message, actual_message]
          in [Fear::None, Fear::Some]
            true
          in [Fear::None, Fear::None]
            false
          in [Fear::Some(expected), Fear::Some(actual)]
            fuzzy_matched?(expected, actual)
          in [Fear::Some, Fear::None]
            false
          end
        end

        def does_not_match?(jailbreak:) = !matches?(jailbreak:)

        def failure_message = message("to")

        def failure_message_when_negated = message("not to")

        private def message(predicate)
          "expected #{predicate} receive #{formatted_expected}, but got #{formatted_actual}"
        end

        private def formatted_expected
          expected_message
            .map { RSpec::Support::ObjectFormatter.format(_1) }
            .get_or_else("any message")
        end

        private def formatted_actual
          actual_message
            .map { RSpec::Support::ObjectFormatter.format(_1) }
            .get_or_else("nothing")
        end
      end
    end
  end
end
