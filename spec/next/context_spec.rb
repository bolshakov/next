# frozen_string_literal: true

RSpec.describe Next::Context, :actor_system do
  describe "#become" do
    let(:actor_class) do
      Class.new(Next::Actor) do
        def receive(message)
          case message
          when :A
            sender.tell(message)
            context.become(:receive2)
          when :B, :D
            sender.tell(message)
          end
        end

        def receive2(message)
          case message
          in :C
            sender.tell(message)
            context.become(:receive)
          in :fail
            raise "expected error"
          end
        end
      end
    end
    let(:actor) { system.actor_of(Next.props(actor_class), "test") }

    it "ignores unhandled :B message" do
      actor.tell :A
      actor.tell :B
      actor.tell :C
      actor.tell :D

      expect_message(:A)
      expect_message(:C)
      expect_message(:D)
    end

    context "when a failure happens" do
      it "gets default behaviour after the restart" do
        actor.tell :A
        actor.tell :B
        actor.tell :fail
        actor.tell :A

        expect_message(:A)
        expect_message(:A)
      end
    end
  end

  describe "#parent" do
    context "when actor is a root actor" do
      let(:actor) { system.actor_of(ChildActor.props) }

      it "is child of user root" do
        actor << :get_parent

        expect_message system.__send__(:user_root)
      end
    end

    context "when actor created by another actor" do
      let(:parent) { system.actor_of(ParentActor.props, "parent") }

      it "is child of user" do
        parent << [:create_child, "child"]
        child = expect_message be_kind_of(Next::Reference).and(have_attributes(name: "child"))

        child << :get_parent
        expect_message parent
      end
    end
  end

  describe "#child" do
    let(:parent) { system.actor_of(ParentActor.props, "parent") }

    context "when child does not exist" do
      it "returns Fear::None" do
        parent << [:get_child, "not created"]

        expect_message be_none
      end
    end

    context "when child exists" do
      it "returns Fear::Some of child" do
        parent << [:create_child, "child"]

        child = expect_message be_kind_of(Next::Reference).and have_attributes(name: "child")

        parent << [:get_child, "child"]

        expect_message be_some_of(child)
      end
    end
  end

  describe "#children" do
    let(:parent) { system.actor_of(ParentActor.props, "parent") }

    context "when there is no children" do
      it "returns empty collection" do
        parent << :get_children

        expect_message be_empty
      end
    end

    context "when there are some children" do
      it "returns empty collection" do
        parent << [:create_child, "child1"]
        parent << [:create_child, "child2"]

        parent << :get_children

        fish_for_message contain_exactly("child1", "child2")
      end
    end
  end
end
