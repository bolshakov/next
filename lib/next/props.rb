# frozen_string_literal: true

module Next
  # Props servers as a configuration object for  +Next::Reference+. It's immutable and safe to share across actors.
  # Use it to create new actors.
  #
  #   props = Next.props(MyActorClass, logger: Logger.new, counter: 0)
  #   context.actor_of(props)
  #
  # you can also pass props to other props as an argument:
  #
  #   worker_props = Next.props(Worker)
  #   manager_props = Next.props(Manager, worker: worker_props, number_of_workers: 10)
  #   manager = context.actor_of(manager_props)
  #   manager.tell(..)
  #
  # @api private use +Next.props+ instead
  class Props
    attr_reader :actor_class
    protected :actor_class

    attr_reader :attributes
    protected :attributes

    def initialize(actor_class, **attributes)
      @actor_class = actor_class
      @attributes = attributes
      freeze
    end

    # Instantiates actor from props
    # @api private
    def __new_actor__(context)
      actor_class.allocate.tap do |actor|
        actor.instance_variable_set(:@context, context)

        if actor.respond_to?(:initialize, true)
          actor.__send__(:initialize, **attributes)
        end
      end
    end

    # @param other [Object]
    # @return [Boolean]
    def ==(other)
      other.is_a?(self.class) &&
        actor_class == other.actor_class &&
        attributes == other.attributes
    end
  end
end
