# frozen_string_literal: true

module Next
  module Testing
    module Expectations
      DEFAULT_TIMEOUT = 3
      # Expects the given message to be received in a given timeout
      #
      # @param expected [any]
      # @param timeout [Integer]
      # @return [any] received messages
      def expect_message(expected = Fear::Utils::UNDEFINED, timeout: DEFAULT_TIMEOUT, &)
        case receive_one(timeout: timeout)
        in Fear::None
          raise ::RSpec::Expectations::ExpectationNotMetError,
            "timeout (#{timeout}) during expect_message while waiting for #{expected.inspect}",
            caller(1)
        in Fear::Some(received)
          expect_match(expected, received, &)

          received.message
        end
      end

      # Expects the given message to be received in a given timeout
      private def receive_one(timeout:)
        Timeout.timeout(timeout) do
          Fear.some(jailbreak.take)
        end
      rescue Timeout::Error
        Fear.none
      end

      private def expect_match(expected, actual, message = nil) # rubocop: disable Metrics/AbcSize
        if expected == Fear::Utils::UNDEFINED && !block_given?
          raise ArgumentError, "pass either expected values or block"
        end

        return yield(*actual.deconstruct) if block_given?

        case expected
        when ::RSpec::Matchers::BuiltIn::BaseMatcher, ::RSpec::Matchers::DSL::Matcher
          expect(actual.message).to expected, (message || "received unexpected messages #{actual.message.inspect} from #{actual.sender.name} ")
        else
          expect(actual.message).to eq(expected), (message || "Expected to receive #{expected.inspect}, but received #{actual.message.inspect} from #{actual.sender.name} ")
        end
      end
    end
  end
end
