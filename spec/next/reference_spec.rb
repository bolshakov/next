# frozen_string_literal: true

RSpec.describe Next::Reference do
  let(:klass) do
    Class.new(Next::Actor) do
      def initialize(starts_at: 0)
        @counter = starts_at
      end
    end
  end

  context "with props" do
    subject(:ref) { described_class.new(props, name: "test", parent: nil) }

    context "with arguments" do
      let(:props) { Next.props(klass, starts_at: 4) }

      it { is_expected.to be_kind_of(Next::Reference) }
      it { is_expected.to have_attributes(name: "test") }
    end

    context "without arguments" do
      let(:props) { Next.props(klass) }

      it { is_expected.to be_kind_of(Next::Reference) }
      it { is_expected.to have_attributes(name: be_kind_of(String)) }
    end
  end

  context "with actor class", pending: "not yet implemented" do
    subject(:ref) { described_class.new(klass, name: "test", parent: nil) }

    it { is_expected.to be_kind_of(Next::Reference) }
    it { is_expected.to have_attributes(name: "test") }
  end

  describe "#tell", :actor_system do
    let(:timout) { 3 }

    context "when actor respond within timeout" do
      subject { Fear::Await.result(future, 3) }

      let(:future) { Fear::Future.new(promise) }
      let(:promise) { Fear::Promise.new }
      let(:actor_class) do
        Class.new(Next::Actor) do
          def initialize(promise:)
            @promise = promise
          end

          def receive(message)
            @promise.success("received: #{message}")
          end

          def executor
            Concurrent::ImmediateExecutor.new
          end
        end
      end

      let(:actor) { system.actor_of(Next.props(actor_class, promise:)) }

      before do
        actor << "foo"
      end

      it "returns response from the actor" do
        is_expected.to eq(Fear.success("received: foo"))
      end
    end
  end

  describe "#ask", :actor_system do
    let(:timout) { 3 }

    context "when actor respond within timeout" do
      subject { Fear::Await.result(actor.ask("foo"), 3) }

      let(:actor) { system.actor_of(EchoActor.props) }

      it "returns response from the actor" do
        is_expected.to be_success_of("foo")
      end
    end
  end

  describe "#ask!", :actor_system do
    subject { actor.ask!("foo") }

    let(:actor) { system.actor_of(EchoActor.props) }

    it "returns response from the actor" do
      is_expected.to be_some_of("foo")
    end
  end

  describe "#path", :actor_system do
    let(:parent_ref) { system.actor_of(ParentActor.props, "path-test-parent") }

    context "when root actor" do
      subject { parent_ref.path }

      it { is_expected.to eq("next://test-system/user/path-test-parent") }
    end

    context "when child actor" do
      subject { child_ref.path }

      let(:child_ref) do
        parent_ref << [:create_child, "path-test-child"]
        expect_message(be_kind_of(Next::Reference))
      end

      it { is_expected.to eq("next://test-system/user/path-test-parent/path-test-child") }
    end
  end
end
