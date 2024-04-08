# frozen_string_literal: true

require "rspec"

RSpec.describe Next::Envelope do
  describe "<=>(other)" do
    subject { this <=> other }

    def envelope(message, posted_at)
      Next::Envelope.new(message:, sender: nil, posted_at:)
    end

    let(:system_message) { Object.new.extend(Next::SystemMessage) }
    let(:not_system_message) { Object.new }

    context "when SystemMessage and SystemMessage" do
      context "when this posted after other" do
        let(:this) { envelope(system_message, 10) }
        let(:other) { envelope(system_message, 1) }

        it { is_expected.to eq(1) }
      end

      context "when this posted before other" do
        let(:this) { envelope(system_message, 1) }
        let(:other) { envelope(system_message, 10) }

        it { is_expected.to eq(-1) }
      end

      context "when this posted at the same time as other" do
        let(:this) { envelope(system_message, 1) }
        let(:other) { envelope(system_message, 1) }

        it { is_expected.to eq(0) }
      end
    end

    context "when SystemMessage and not SystemMessage" do
      context "when this posted after other" do
        let(:this) { envelope(system_message, 10) }
        let(:other) { envelope(not_system_message, 1) }

        it { is_expected.to eq(1) }
      end

      context "when this posted before other" do
        let(:this) { envelope(system_message, 1) }
        let(:other) { envelope(not_system_message, 10) }

        it { is_expected.to eq(1) }
      end

      context "when this posted at the same time as other" do
        let(:this) { envelope(system_message, 1) }
        let(:other) { envelope(not_system_message, 1) }

        it { is_expected.to eq(1) }
      end
    end

    context "when not SystemMessage and SystemMessage" do
      context "when this posted after other" do
        let(:this) { envelope(not_system_message, 10) }
        let(:other) { envelope(system_message, 1) }

        it { is_expected.to eq(-1) }
      end

      context "when this posted before other" do
        let(:this) { envelope(not_system_message, 1) }
        let(:other) { envelope(system_message, 10) }

        it { is_expected.to eq(-1) }
      end

      context "when this posted at the same time as other" do
        let(:this) { envelope(not_system_message, 1) }
        let(:other) { envelope(system_message, 1) }

        it { is_expected.to eq(-1) }
      end
    end

    context "when not SystemMessage and not SystemMessage" do
      context "when this posted after other" do
        let(:this) { envelope(not_system_message, 10) }
        let(:other) { envelope(not_system_message, 1) }

        it { is_expected.to eq(1) }
      end

      context "when this posted before other" do
        let(:this) { envelope(not_system_message, 1) }
        let(:other) { envelope(not_system_message, 10) }

        it { is_expected.to eq(-1) }
      end

      context "when this posted at the same time as other" do
        let(:this) { envelope(not_system_message, 1) }
        let(:other) { envelope(not_system_message, 1) }

        it { is_expected.to eq(0) }
      end
    end
  end
end
