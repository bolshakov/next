# frozen_string_literal: true

module Next
  # Represents an event stream that allows subscribing and publishing events.
  #
  # @see Next::EventBus
  # @api private
  class EventStream
    attr_reader :event_bus

    def initialize(event_bus:)
      @event_bus = event_bus
    end

    # Subscribes a subscriber to an event on the event bus.
    #
    # @param subscriber The subscriber Reference to be subscribed.
    # @param event The event to be subscribed to (should respond to +#===+ method).
    def subscribe(subscriber, event)
      raise ArgumentError, "subscriber should be type of Reference" unless subscriber.is_a?(Reference)

      event_bus.tell EventBus::Subscribe.new(event:, subscriber:)

      self
    end

    # Publishes an event to the event bus.
    #
    # @param [Object] event The event to be published.
    # @return [EventStream] The EventStream instance.
    def publish(event)
      event_bus.tell EventBus::Publish.new(event:)

      self
    end
  end
end
