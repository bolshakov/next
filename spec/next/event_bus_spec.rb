# frozen_string_literal: true

RSpec.describe Next::EventBus, :actor_system do
  let(:event_bus) { system.actor_of(described_class.props) }

  def subscribe(...) = Next::EventBus::Subscribe.new(...)

  def unsubscribe(...) = Next::EventBus::Unsubscribe.new(...)

  def publish(...) = Next::EventBus::Publish.new(...)

  context "when subscribed to the same event twice" do
    before do
      event_bus.tell subscribe(event: Numeric, subscriber: test_probe)
      event_bus.tell subscribe(event: Numeric, subscriber: test_probe)
    end

    it "does not receive the same event twice" do
      event_bus.tell publish(event: 42)

      expect_message(42)
      expect_no_message(timeout: 0.1)
    end
  end

  context "when subscribed a superclass of an event" do
    before do
      event_bus.tell subscribe(event: Numeric, subscriber: test_probe)
    end

    it "receives matching event" do
      event_bus.tell publish(event: 42.0)

      expect_message(42.0)
    end
  end

  context "when subscribed a superclass of an event and to event itself" do
    before do
      event_bus.tell subscribe(event: Numeric, subscriber: test_probe)
      event_bus.tell subscribe(event: Float, subscriber: test_probe)
    end

    it "does not receive the same event twice" do
      event_bus.tell publish(event: 42.0)

      expect_message(42.0)
      expect_no_message(timeout: 0.1)
    end
  end

  context "when subscribed a subclass of an event" do
    before do
      event_bus.tell subscribe(event: Float, subscriber: test_probe)
    end

    it "does not receive an event" do
      event_bus.tell publish(event: 42)

      expect_no_message(timeout: 0.1)
    end
  end

  context "when two different subscribers subscribed to the same event" do
    let(:subscriber1) { system.actor_of(ActorWithInspector.props(inspector: test_probe)) }
    let(:subscriber2) { system.actor_of(ActorWithInspector.props(inspector: test_probe)) }

    before do
      event_bus.tell subscribe(event: Numeric, subscriber: subscriber1)
      event_bus.tell subscribe(event: Numeric, subscriber: subscriber2)
    end

    it "each subscriber receives an event" do
      event_bus.tell publish(event: 42)

      expect_message(42)
      expect_message(42)
    end
  end

  context "when unsubscribed" do
    before do
      event_bus.tell subscribe(event: Numeric, subscriber: test_probe)
    end

    it "does not receive any events" do
      event_bus.tell unsubscribe(subscriber: test_probe)

      event_bus.tell publish(event: 42)

      expect_no_message(timeout: 0.1)
    end
  end
end
