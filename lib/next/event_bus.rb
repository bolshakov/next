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
    Publish = Data.define(:event)

    def self.props = Next.props(self)

    def initialize
      @subscriptions = Hash.new do |subscribers, matcher|
        subscribers[matcher] = Set.new
      end
      context.log.debug("Event Bus started")
    end

    def receive(message)
      case message
      in :initialize
        sender << :initialized
      in Subscribe(event:, subscriber:)
        create_subscription(event:, subscriber:)
      in Publish(event:)
        publish_event(event:)
      end
    end

    private def create_subscription(event:, subscriber:)
      subscriptions[event].add(subscriber)
    end

    private def publish_event(event:)
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
