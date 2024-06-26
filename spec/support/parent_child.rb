# frozen_string_literal: true

require "support/actor_with_inspector"

class ChildActor < ActorWithInspector
  def receive(message)
    if message == :get_parent
      inspector << context.parent
    else
      super(message)
    end
  end

  def post_stop
    inspector << "#{identity.name} stopped"
  end
end

class ParentActor < ActorWithInspector
  attr_reader :child

  def receive(message)
    case message
    in [:get_child, name]
      inspector << context.child(name)
    in [:create_child, name]
      inspector << context.actor_of(ChildActor.props(inspector:), name)
    in :get_children
      inspector << context.children.map(&:name)
    else
      super(message)
    end
  end

  def post_stop
    inspector << "#{identity.name} stopped"
  end
end
