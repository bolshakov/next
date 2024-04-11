# frozen_string_literal: true

module Next
  # Base class for all actors
  class Actor
    # Entry point to actor's API
    attr_reader :context

    class << self
      def executor
        Next.default_executor
      end
    end

    def sender
      context.sender
    end

    # @api private
    def around_post_stop = post_stop

    # User-overridable callback executed after stopping an actor
    def post_stop
    end
  end
end
