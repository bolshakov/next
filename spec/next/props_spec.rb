# frozen_string_literal: true

RSpec.describe Next::Props do
  describe "#__new_actor__" do
    subject { props.__new_actor__(context) }

    let(:context) { instance_double(Next::Context, identity: ref) }
    let(:ref) { instance_double(Next::Reference) }

    context "without arguments" do
      let(:props) { described_class.new(actor_class) }

      let(:actor_class) { Class.new(Next::Actor) }

      it { is_expected.to be_kind_of(actor_class) }
      it { is_expected.to have_attributes(context: context) }
    end

    context "with arguments" do
      let(:props) { described_class.new(actor_class, **attributes) }
      let(:attributes) { {foo: "foo", bar: 42} }

      let(:actor_class) do
        Class.new(Next::Actor) do
          def initialize(foo:, bar:)
            @foo = foo
            @bar = bar

            super()
          end

          attr_reader :foo, :bar
        end
      end

      it { is_expected.to be_kind_of(actor_class) }
      it { is_expected.to have_attributes(attributes) }
    end

    context "with initializer accessing actor's context" do
      let(:props) { described_class.new(actor_class) }

      let(:actor_class) do
        Class.new(Next::Actor) do
          def initialize
            context.identity

            super
          end
        end
      end

      it { is_expected.to be_kind_of(actor_class) }
    end
  end
end
