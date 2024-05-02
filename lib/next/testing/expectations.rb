# frozen_string_literal: true

module Next
  module Testing
    module Expectations
      DEFAULT_TIMEOUT = 3

      # Expects the given message to be received in a given timeout
      #
      # @param expected_message [any]
      # @param timeout [Numeric]
      # @return [any] received message
      def expect_message(expected_message, timeout: DEFAULT_TIMEOUT)
        matcher = Matchers::ExpectMessage.new(Fear.some(expected_message), timeout:)

        if matcher.matches?(jailbreak: test_probe_jailbreak)
          matcher.actual_message.get
        else
          raise ::RSpec::Expectations::ExpectationNotMetError,
            matcher.failure_message,
            caller(1)
        end
      end

      # Expects no messages to be received in a given timeout
      #
      # @param timeout [Numeric]
      def expect_no_message(timeout: DEFAULT_TIMEOUT)
        matcher = Matchers::ExpectMessage.new(Fear.none, timeout:)

        if matcher.matches?(jailbreak: test_probe_jailbreak)
          raise ::RSpec::Expectations::ExpectationNotMetError,
            matcher.failure_message_when_negated,
            caller(1)
        end
      end

      # Expect all messages to be received within a given timeout. The order of messages does not matter
      #
      # @param expected_messages [Array]
      # @param timeout [Numeric]
      # @return [Array] captured messages
      def expect_all_messages(*expected_messages, timeout: DEFAULT_TIMEOUT)
        matcher = Matchers::ExpectAllMessages.new(expected_messages, timeout: timeout)

        if matcher.matches?(jailbreak: test_probe_jailbreak)
          matcher.actual_messages
        else
          raise ::RSpec::Expectations::ExpectationNotMetError,
            matcher.failure_message,
            caller(1)
        end
      end

      # Waits for a specific message from the test_probe, ensuring that the expected message is
      # received within a given timeout period (3 seconds by default).
      #
      # @param expected_message [any]
      # @param timeout [Numeric]
      # @return [any] received message
      def fish_for_message(expected_message, timeout: DEFAULT_TIMEOUT)
        matcher = Matchers::FishForMessage.new(expected_message, timeout:)

        if matcher.matches?(jailbreak: test_probe_jailbreak)
          matcher.actual_message
        else
          raise ::RSpec::Expectations::ExpectationNotMetError,
            matcher.failure_message,
            caller(1)
        end
      end

      def expect_log(expected_message, level: nil, timeout: DEFAULT_TIMEOUT)
        matcher = Matchers::FishForLog.new(expected_message, level:, timeout:)

        if matcher.matches?(jailbreak: test_logs_listener_jailbreak)
          matcher.actual_message
        else
          raise ::RSpec::Expectations::ExpectationNotMetError,
            matcher.failure_message,
            caller(1)
        end
      end

      # Waits until a condition is met within a given timeout period.
      def await_condition(timeout: DEFAULT_TIMEOUT, interval: 0.01, message: "condition is not met")
        wail_till = Time.now + timeout

        condition_met = false

        loop do
          remaining_timout = wail_till - Time.now
          break if remaining_timout <= 0

          if yield
            condition_met = true
            break
          end
          sleep interval
        end

        unless condition_met
          raise ::RSpec::Expectations::ExpectationNotMetError,
            "timout (#{timeout}) expired: #{message}",
            caller(1)
        end
      end
    end
  end
end
