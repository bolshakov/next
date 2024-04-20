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

    # Shortened for +context.sender+. Refers to a sender of a last message.
    def sender = context.sender

    # Shortened for +context.identity+. You cas send messages to yourself using this handler.
    def identity = context.identity

    # @api private
    def around_pre_start = pre_start

    # User-overridable callback.
    def pre_start
    end

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

    # Supervision strategy. It is applied to actor's children.
    def supervisor_strategy = SupervisorStrategy.default_strategy
  end
end
