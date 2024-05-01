# frozen_string_literal: true

begin
  require "concurrent/channel"
rescue LoadError
  puts "You must add 'concurrent-ruby-edge' to your Gemfile in order to use testing helpers"
end

module Next
  module Testing
    # It puts all the received messages into +jailbreak+.
    #
    # @api private
    class TestActor < Actor
      def self.build(system)
        jailbreak = self.jailbreak
        props = self.props(jailbreak:)
        [jailbreak, system.actor_of(props, "test-actor-2-" + SecureRandom.uuid)]
      end

      def self.props(jailbreak:) = Next.props(self, jailbreak:)

      def self.jailbreak = Concurrent::Channel.new

      attr_reader :jailbreak
      private :jailbreak

      def initialize(jailbreak:)
        @jailbreak = jailbreak
      end

      def receive(message)
        case message
        when :__initialize__
          sender << :initialized
        else
          Concurrent::Channel.go do
            jailbreak << message
          end
        end
      end

      def post_stop
        jailbreak.stop
      end
    end
  end
end
