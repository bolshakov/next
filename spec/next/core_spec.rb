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
  end

  describe Next::SystemMessages::Terminate do
    subject(:terminate) { Fear::Await.result(termination_future, 3) }

    let(:termination_future) { echo.stop }
    let(:echo) { system.actor_of(EchoActor.props) }

    it "returns termination future which is resolved eventually" do
      is_expected.to be_success_of(Next::Terminated.new(echo))
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
end
