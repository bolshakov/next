# frozen_string_literal: true

module Next
  # Base class for all actors
  class Actor
    # Entry point to actor's API
    attr_reader :context

    def executor
      context.executor
    end

    def sender
      context.sender
    end
  end
end
