# frozen_string_literal: true

RSpec.describe Next::SerializedPriorityExecution::Job do
  describe "#<=>" do
    subject { this <=> other }

    let(:this) { described_class.new(nil, [this_envelope], -> {}) }
    let(:other) { described_class.new(nil, [other_envelope], -> {}) }
    let(:this_envelope) { Next::Envelope.new(message: nil, sender: nil) }
    let(:other_envelope) { Next::Envelope.new(message: nil, sender: nil) }

    it do
      expect(this_envelope).to receive(:<=>).with(other_envelope) { 42 }

      is_expected.to eq(42)
    end
  end
end
