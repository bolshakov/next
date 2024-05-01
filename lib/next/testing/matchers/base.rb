# frozen_string_literal: true

module Next
  module Testing
    module Matchers
      class Base
        DEFAULT_TIMEOUT = 3 # in seconds
        public_constant :DEFAULT_TIMEOUT

        private def receive_one(jailbreak:, timeout:)
          Timeout.timeout(timeout) do
            Fear.some(jailbreak.take)
          end
        rescue Timeout::Error
          Fear.none
        end

        private def fuzzy_matched?(expected, actual)
          ::RSpec::Support::FuzzyMatcher.values_match?(expected, actual)
        end

        private def receive_many(n, jailbreak:, timeout:)
          deadline = Time.now + timeout
          messages = []

          loop do
            remaining_timeout = deadline - Time.now
            remaining_timeout = 0 if remaining_timeout < 0

            case receive_one(jailbreak:, timeout: remaining_timeout)
            in Fear::None
              break
            in Fear::Some(received)
              messages.push(received)
              break if messages.size >= n
            end
          end

          messages
        end
      end
    end
  end
end
