# frozen_string_literal: true

RSpec.describe Next::Context, :actor_system do
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
