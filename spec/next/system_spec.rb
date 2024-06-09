# frozen_string_literal: true

require "support/parent_child"
require "support/echo_actor"

RSpec.describe Next::System, :actor_system do
  describe "#actor_of" do
    let(:name) { "actor-of-test" }

    context "when actor with this name is not exists" do
      subject(:actor) { system.actor_of(ChildActor.props, name) }

      it { is_expected.to be_kind_of(Next::Reference) }

      it "user root is a parent" do
        actor << :get_parent

        expect_message(have_attributes(name: "user"))
      end
    end

    context "when actor with this name is already exists" do
      before do
        system.actor_of(EchoActor.props, name)
      end

      specify "raises ActorNameError" do
        expect do
          system.actor_of(EchoActor, name)
        end.to raise_error(Next::ActorNameError)
      end
    end
  end

  describe "#terminate" do
    let(:system) { Next.system("test-system") }

    it "does not create actors after termination" do
      system.terminate!

      expect do
        system.actor_of(EchoActor.props, "echo2", timeout: 0.1)
      end.to raise_error(Timeout::Error)
    end
  end

  describe "#event_stream" do
    let(:event_stream) { system.event_stream }

    it "subscribes to events" do
      event_stream.subscribe(test_probe, Numeric)

      event_stream.publish(42)
      expect_message(42)

      event_stream.publish(42.2)
      expect_message(42.2)
    end

    context "when subscriber is not a reference" do
      let(:invalid_subscriber) { double }

      it "raises an ArgumentError" do
        expect {
          event_stream.subscribe(invalid_subscriber, 42)
        }.to raise_error ArgumentError, "subscriber should be type of Reference"
      end
    end
  end

  describe "#log" do
    let(:system) { Next.system("test") }
    let(:event_stream) { system.event_stream }
    let(:subscriber) { system.actor_of(ActorWithInspector.props(inspector: test_probe)) }

    it "receives log events" do
      event_stream.subscribe(subscriber, Next::Logger::LogEvent)

      system.log.info("Log event", "specs")

      expect_message(Next::Logger::Info.new(message: "Log event", progname: "specs"))
    end
  end
end
