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

    def sender = context.sender

    # @api private
    def around_post_stop = post_stop

    # User-overridable callback executed after stopping an actor
    def post_stop
    end

    # @api private
    def around_pre_restart(reason:, message:) = pre_restart(reason: reason, message: message)

    # User-overridable callback. By default it stops child actors and calls +post_stop+ hook.
    def pre_restart(reason:, message:)
      context.children.each do |child|
        child.tell SystemMessages::Terminate
      end

      post_stop
    end

    # @api private
    def around_post_restart(reason:) = post_restart(reason: reason)

    # User-overridable callback. By default it calls +pre_start+ hook.
    def post_restart(reason:) = pre_start

    # User-overridable callback.
    def pre_start
    end

    def supervision_strategy = SupervisionStrategy.default_strategy
  end
end
