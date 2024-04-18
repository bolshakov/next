# frozen_string_literal: true

module Next
  class ActorInitializationError < Error
    def initialize(message, reference)
      super("#{reference.name}: #{message}")
    end
  end
end
