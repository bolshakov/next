# frozen_string_literal: true

module Next
  # The EventBus class enables other actors to subscribe to specific events and receive
  # notifications when these events are published to the event bus. Here is an example of
  # how to use this functionality:
  #
  #   event_bus = system.actor_of(EventBus.props)
  #   event_bus.tell EventBus::Subscribe.new(event: Numeric, subscriber: actor_ref2)
  #   event_bus.tell EventBus::Subscribe.new(event: Float, subscriber: actor_ref2)
  #   event_bus.tell EventBus::Publish.new(event: 42.2)
  #
  # In the above example, only +actor_ref2+ receives the +42.2+ message. However, if you publish +424+
  # it will be received by both actors.
  #
  # TODO: unsubscribe terminated actors
  #
  # @api private
  class EventBus < Actor
    attr_reader :subscriptions

    Subscribe = Data.define(:event, :subscriber)
    Unsubscribe = Data.define(:subscriber)
    Publish = Data.define(:event)

    def self.props = Next.props(self)

    def initialize
      @subscriptions = Hash.new do |subscriptions, matcher|
        subscriptions[matcher] = Set.new
      end
      context.log.debug("Event Bus started")
    end

    def receive(message)
      case message
      in :initialize
        sender << :initialized
      in Subscribe(event:, subscriber:)
        subscribe(event:, subscriber:)
      in Unsubscribe(subscriber:)
        unsubscribe(subscriber:)
      in Publish(event:)
        publish(event:)
      end
    end

    private def subscribe(event:, subscriber:)
      subscriptions[event].add(subscriber)
    end

    private def unsubscribe(subscriber:)
      subscriptions.each do |_, subscribers|
        subscribers.delete(subscriber)
      end
    end

    private def publish(event:)
      subscribers(event).each do |subscriber|
        subscriber.tell(event)
      end
    end

    private def subscribers(event)
      subscriptions.each_with_object(Set.new) do |(matcher, subscribers), acc|
        if matcher === event
          acc.merge(subscribers)
        end
      end
    end
  end
end
