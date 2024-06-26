# frozen_string_literal: true

require "support/echo_actor"

RSpec.describe Next::Core, :actor_system do
  describe Next::PoisonPill do
    let(:echo) { system.actor_of(EchoActor.props) }

    it "does not receive any messages after PoisonPill" do
      echo.tell :foo
      echo.tell Next::PoisonPill

      echo.tell :bar

      expect_message(:foo)
      expect_no_message(timeout: 0.2)
    end

    describe "config.debug.autoreceive" do
      let(:system) { Next.system("test", config) }
      let(:config) do
        Next::ConfigFactory.new.load(
          next: {
            debug: {autoreceive: debug_autoreceive}
          }
        )
      end

      context "when enabled" do
        let(:debug_autoreceive) { true }

        it "logs" do
          echo.tell Next::PoisonPill

          expect_log("received AutoReceiveMessage #<Next::PoisonPill>", level: :debug)
        end
      end

      context "when disabled" do
        let(:debug_autoreceive) { false }

        it "does not log" do
          echo.tell Next::PoisonPill

          expect_no_log(/received AutoReceiveMessage/, timeout: 0.2)
        end
      end
    end
  end

  describe Next::SystemMessages::Terminate do
    subject(:terminate) { Fear::Await.result(termination_future, 3) }

    let(:termination_future) { echo.stop }
    let(:echo) { system.actor_of(EchoActor.props) }

    it "returns termination future which is resolved eventually" do
      is_expected.to be_success_of(Next::Terminated.new(echo))
    end

    context "when message received after Terminate" do
      it "sends it to the dead queue" do
      end
    end

    context "when an actor has children" do
      let(:termination_future) do
        Fear.for(parent_termination_future, child1_termination_future, child2_termination_future) do
          [_1, _2, _3]
        end
      end

      let(:parent_termination_future) { parent.stop }
      let(:child1_termination_future) { child1.stop }
      let(:child2_termination_future) { child2.stop }

      let(:parent) { system.actor_of(ParentActor.props, "parent") }
      let!(:child1) do
        parent.tell([:create_child, "child-1"])
        expect_message(be_kind_of(Next::Reference))
      end
      let!(:child2) do
        parent.tell([:create_child, "child-2"])
        expect_message(be_kind_of(Next::Reference))
      end

      it "terminates parent and its children" do
        is_expected.to be_success_of(
          [
            Next::Terminated.new(parent),
            Next::Terminated.new(child1),
            Next::Terminated.new(child2)
          ]
        )
      end

      it "terminates children before the parent" do
        terminate

        expect_message("child-1 stopped")
        expect_message("child-2 stopped")
        expect_message("parent stopped")
      end
    end
  end

  describe "system.config.next.debug.receive" do
    let(:actor_ref) { system.actor_of(actor_class.props) }
    let(:actor_class) do
      Class.new(Next::Actor) do
        def self.props = Next.props(self)

        def receive(message)
          case message
          in "kawabanga"
          # noop
          in "fail"
            raise "foo"
          end
        end
      end
    end
    let(:system) { Next.system("test", config) }
    let(:config) do
      Next::ConfigFactory.new.load(
        next: {
          debug: {receive: debug_receive}
        }
      )
    end

    context "when enabled" do
      let(:debug_receive) { true }
      it "logs when received handled message" do
        actor_ref.tell "kawabanga"

        expect_log "received handled message `\"kawabanga\"` from '#{test_probe.name}`", level: :debug
      end
    end

    context "when disabled" do
      let(:debug_receive) { false }

      it "does not log when received handled message" do
        actor_ref.tell "kawabanga"

        expect_no_log(/received handled message `"kawabanga"`/, timeout: 0.05)
      end
    end
  end

  describe "system.config.debug.unhandled" do
    let(:actor_ref) { system.actor_of(actor_class.props) }
    let(:actor_class) do
      Class.new(Next::Actor) do
        def self.props = Next.props(self)

        def receive(message)
          case message
          in "kawabanga"
            # noop
          end
        end
      end
    end
    let(:system) { Next.system("test", config) }
    let(:config) { Next::ConfigFactory.new.load({next: {debug: {unhandled: debug_unhandled}}}) }

    context "when enabled" do
      let(:debug_unhandled) { true }

      it "logs when received unhandled message" do
        actor_ref.tell "Hi! How are you?"

        expect_log "received unhandled message `\"Hi! How are you?\"` from '#{test_probe.name}`", level: :debug
      end
    end

    context "when disabled" do
      let(:debug_unhandled) { false }

      it "does not log when received handled message" do
        actor_ref.tell "Hi! How are you?"

        expect_no_log(/received unhandled message/, timeout: 0.05)
      end
    end
  end

  describe "system.config.debug.lifecycle" do
    let(:actor_ref) { system.actor_of(actor_class.props, "destroyer") }
    let(:actor_class) do
      Class.new(Next::Actor) do
        def self.props = Next.props(self)

        def receive(message)
        end
      end
    end
    let(:system) { Next.system("test", config) }
    let(:config) { Next::ConfigFactory.new.load({next: {debug: {lifecycle: debug_lifecycle}}}) }

    context "when enabled" do
      let(:debug_lifecycle) { true }

      it "logs" do
        actor_ref.tell "Hi! How are you?"

        expect_log "created", level: :debug
      end
    end

    context "when disabled" do
      let(:debug_lifecycle) { false }

      it "does not log" do
        actor_ref.tell "Hi! How are you?"

        expect_no_log(/created/, timeout: 0.05)
      end
    end
  end
end
