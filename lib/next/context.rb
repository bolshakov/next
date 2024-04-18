# frozen_string_literal: true

module Next
  # Actor Context is an actor's interface from the actor's point of view.
  # Every actor can access it by calling +#context+
  #
  # Warning: Context should never be shared outside of the actor
  #
  # @api public
  module Context
    # Refers to actor's own +Reference+
    attr_accessor :identity
    private :identity=

    attr_accessor :parent
    private :parent=

    def initialize
      super()

      synchronize do
        @children = {}
      end
    end

    # Spawn a new child actor and supervise it
    #
    def actor_of(props, name = SecureRandom.uuid)
      if @children.has_key?(name.to_s)
        raise ActorNameError, "name #{name.inspect} is already used by another actor"
      else
        Reference.new(props, name:).tap do |child|
          identity << SystemMessages::Supervise.new(child)
        end
      end
    end

    def sender
      LocalStorage.sender
    end

    # Gets child with the given name
    def child(name)
      Fear.option(@children[name.to_s])
    end

    # Gets children of this actor
    def children
      Set.new(@children.values)
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

    # Asynchronously terminates child by reference
    def stop(child)
      child_by_reference(child).each do
        child << SystemMessages::Terminate
      end
    end
  end
end
