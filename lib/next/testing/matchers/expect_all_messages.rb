# frozen_string_literal: true

module Next
  module Testing
    module Matchers
      class ExpectAllMessages < Base
        attr_reader :expected_messages
        attr_reader :actual_messages
        attr_reader :timeout
        attr_reader :matcher

        def initialize(expected_messages, timeout: DEFAULT_TIMEOUT)
          @expected_messages = expected_messages
          @timeout = timeout
          @matcher = RSpec::Matchers::BuiltIn::ContainExactly.new(expected_messages)
        end

        def matches?(jailbreak:)
          @actual_messages = receive_many(expected_messages.count, jailbreak:, timeout:)

          matcher.matches?(@actual_messages)
        end

        def failure_message = matcher.failure_message
      end
    end
  end
end
