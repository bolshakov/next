# frozen_string_literal: true

module Next
  # Actor Context is an actor's interface from the actor's point of view.
  # Every actor can access it by calling +#context+
  #
  # @api public
  module Context
    # Refers to actor's own +Reference+
    #
    # @!attribute identity
    #   @return [Next::Reference]
    attr_accessor :identity
    private :identity=

    def executor
      Next.default_executor
    end

    def sender
      LocalStorage.sender
    end
  end
end
