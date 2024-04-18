# frozen_string_literal: true

module Next
  module SystemMessages
    # Lets parent know its child has terminated
    #
    class DeathWatchNotification
      include SystemMessage

      attr_reader :actor
      private :actor

      def initialize(actor)
        @actor = actor
        freeze
      end

      def deconstruct
        [actor]
      end

      def deconstruct_key
        {actor:}
      end

      def inspect
        "#<#{self.class.name} actor=#{actor.name}>"
      end
    end
  end
end
