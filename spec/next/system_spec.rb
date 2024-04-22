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
    let(:echo) { system.actor_of(EchoActor.props, "echo1") }

    it "does not create actors after termination" do
      system.terminate

      system.actor_of(EchoActor.props, "echo2").tell "sent after termination"

      expect_no_message
    end
  end
end
