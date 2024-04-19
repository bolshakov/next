# frozen_string_literal: true

require "support/supervision"

RSpec.describe Next::AllForOneStrategy, :actor_system do
  subject(:handle_failure) do
    supervisor_strategy.handle_failure(
      cause: error,
      child: supervised,
      context: supervisor_context
    )
  end

  let(:supervisor_strategy) do
    described_class.new do |error|
      case error
      when NoMethodError then Next::SupervisorStrategy::RESUME
      when ZeroDivisionError then Next::SupervisorStrategy::RESTART
      when ArgumentError then Next::SupervisorStrategy::STOP
      when NotImplementedError then Next::SupervisorStrategy::ESCALATE
      end
    end
  end

  let(:supervised) { instance_double(Next::Reference) }
  let(:non_failing_supervised) { instance_double(Next::Reference) }
  let(:supervisor_context) { instance_double(Next::Context, children: children) }
  let(:children) { Set[supervised, non_failing_supervised] }

  context "when decider resolves to RESUME" do
    let(:error) { NoMethodError.new(error_message) }
    let(:error_message) { "something went wrong" }

    it "sends SystemMessages::Resume to supervised and returns true" do
      expect(supervised).to receive(:tell) do |message|
        case message
        in Next::SystemMessages::Resume(cause)
          expect(cause).to eq(error)
        end
      end

      expect(handle_failure).to eq(true)
    end
  end

  context "when decider resolves to RESTART" do
    let(:error) { ZeroDivisionError.new(error_message) }
    let(:error_message) { "something went wrong" }

    it "sends SystemMessages::Recreate to all supervises and returns true" do
      [supervised, non_failing_supervised].each do |child|
        expect(child).to receive(:tell).with(Next::SystemMessages::Suspend).ordered
        expect(child).to receive(:tell).with(be_kind_of(Next::SystemMessages::Recreate)).ordered
      end

      expect(handle_failure).to eq(true)
    end
  end

  context "when decider resolves to STOP" do
    let(:error) { ArgumentError.new(error_message) }
    let(:error_message) { "something went wrong" }

    it "stops supervised and returns true" do
      expect(supervisor_context).to receive(:stop).with(supervised)
      expect(supervisor_context).to receive(:stop).with(non_failing_supervised)

      expect(handle_failure).to eq(true)
    end
  end

  context "when decider resolves to ESCALATE" do
    let(:error) { NotImplementedError.new(error_message) }
    let(:error_message) { "something went wrong" }

    it "returns false" do
      expect(supervisor_context).not_to receive(:stop)
      expect(supervised).not_to receive(:tell)
      expect(non_failing_supervised).not_to receive(:tell)

      expect(handle_failure).to eq(false)
    end
  end

  context "when decider does not resolve" do
    let(:error) { Next::Error.new(error_message) }
    let(:error_message) { "something went wrong" }

    it "returns false" do
      expect(supervisor_context).not_to receive(:stop)
      expect(supervised).not_to receive(:tell)
      expect(non_failing_supervised).not_to receive(:tell)

      expect(handle_failure).to eq(false)
    end
  end
end
