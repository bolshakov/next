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
      def self.props(jailbreak:) = Next.props(self, jailbreak:)

      def self.jailbreak = Concurrent::Channel.new

      attr_reader :jailbreak
      private :jailbreak

      def initialize(jailbreak:)
        @jailbreak = jailbreak
      end

      def receive(message)
        Envelope.new(message:, sender:).then do |envelope|
          Concurrent::Channel.go do
            jailbreak << envelope
          end
        end
      end
    end
  end
end
