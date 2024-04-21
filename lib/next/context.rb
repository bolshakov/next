# frozen_string_literal: true

module Next
  # Actor Context is an actor's interface from the actor's point of view.
  # Every actor can access it by calling +#context+ method.
  #
  # Warning: Context should never be shared outside of the actor
  #
  # @api public
  module Context
    DEFAULT_BEHAVIOUR = :receive
    public_constant(:DEFAULT_BEHAVIOUR)

    # Refers to actor's own +Reference+. Therefore an actor
    # can send a message to itself.
    #
    # @example
    #   def receive(message)
    #     case message
    #     in :increment
    #       @counter += 1
    #       # Send message to itself to increment if threshold not reached
    #       context.identity.tell(:increment) if @counter < @threshold
    #     end
    #   end
    #
    attr_accessor :identity
    private :identity=

    # Refers to actor's parent +Reference+. Therefore an actor
    # can send a message to its parent (and supervisor).
    #
    # @example
    #   def receive(job)
    #     context.parent << process(job)
    #   end
    #
    attr_accessor :parent
    private :parent=

    # Refers to the actor system
    attr_reader :system

    attr_reader :current_behaviour
    private :current_behaviour

    def initialize
      super()

      synchronize do
        @children = {}
      end
    end

    # Change actor's behaviour
    # @param behaviour refers to a method name implementing this behaviour
    #
    # @example
    #   def receive(message)
    #     case message
    #     in 'Become happy'
    #       context.become(:happy)
    #     end
    #   end
    #
    #   def happy(message)
    #     # ...
    #   end
    #
    def become(behaviour)
      @current_behaviour = behaviour
      self
    end

    # Spawn a new child actor and supervise it
    #
    # @example
    #   context.actor_of(Worker.props, "worker-1")
    #
    # @see {#child, #children, #stop}
    #
    def actor_of(props, name = SecureRandom.uuid)
      if @children.has_key?(name.to_s)
        raise ActorNameError, "name #{name.inspect} is already used by another actor"
      else
        Reference.new(props, name:, parent: identity, system:).tap do |child|
          identity << SystemMessages::Supervise.new(child)
        end
      end
    end

    # Returns the sender of the current message
    #
    # @example
    #   def receive(command)
    #     case command
    #     in ['*', multiplier]
    #      sender.send(@value * multiplier)
    #     end
    #   end
    #
    def sender
      LocalStorage.sender
    end

    # Gets child with the given name
    #
    # @example
    #   context.child("worker") #=> #<Fear::Option value=#<Reference...>>
    #
    def child(name)
      Fear.option(@children[name.to_s])
    end

    # Gets children of this actor
    #
    # @example
    #   context.children #=> [#<Reference...>, #<Reference...>, ...]
    #
    def children
      Set.new(@children.values)
    end

    # Asynchronously terminates child by reference
    #
    # @example
    #   context.stop(worker)
    #
    def stop(child)
      child_by_reference(child).each do
        child << SystemMessages::Terminate
      end
    end

    # Unregister child
    private def add_child(child)
      synchronize do
        @children[child.name] = child
      end
    end

    # Unregister child
    private def remove_child(child)
      @children.delete_if do |_key, value|
        value == child
      end
    end

    # Gets child with the given +Reference+
    private def child_by_reference(reference)
      if @children.has_value?(reference)
        Fear.some(reference)
      else
        Fear.none
      end
    end
  end
end
