# frozen_string_literal: true

RSpec.describe Next do
  it "has a version number" do
    expect(Next::VERSION).not_to be nil
  end

  describe ".props" do
    subject { described_class.props(actor_class, foo: 42) }

    let(:actor_class) { Class.new(Next::Actor) }

    it { is_expected.to eq(Next::Props.new(actor_class, foo: 42)) }
  end
end
