# frozen_string_literal: true

require "support/supervision"

RSpec.describe Next::OneForOneStrategy do
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

  subject(:handle_failure) do
    supervisor_strategy.handle_failure(
      cause: error,
      child: supervised,
      context: supervisor_context
    )
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

    it "sends SystemMessages::Recreate to supervised and returns true" do
      expect(supervised).to receive(:tell) do |message|
        case message
        in Next::SystemMessages::Recreate(cause)
          expect(cause).to eq(error)
        end
      end

      expect(handle_failure).to eq(true)
    end
  end

  context "when decider resolves to STOP" do
    let(:error) { ArgumentError.new(error_message) }
    let(:error_message) { "something went wrong" }

    it "stops supervised and returns true" do
      expect(supervisor_context).to receive(:stop).with(supervised)

      expect(handle_failure).to eq(true)
    end
  end

  context "when decider resolves to ESCALATE" do
    let(:error) { NotImplementedError.new(error_message) }
    let(:error_message) { "something went wrong" }

    it "returns false" do
      expect(supervisor_context).not_to receive(:stop)
      expect(supervised).not_to receive(:tell)

      expect(handle_failure).to eq(false)
    end
  end

  context "when decider does not resolve" do
    let(:error) { Next::Error.new(error_message) }
    let(:error_message) { "something went wrong" }

    it "returns false" do
      expect(supervisor_context).not_to receive(:stop)
      expect(supervised).not_to receive(:tell)

      expect(handle_failure).to eq(false)
    end
  end

  context "when decider raises NoMatchingPatternError" do
    let(:error) { Next::Error.new(error_message) }
    let(:error_message) { "something went wrong" }
    let(:supervisor_strategy) do
      described_class.new do |error|
        case error
        in NoMethodError then Next::SupervisorStrategy::RESUME
        end
      end
    end

    it "returns false" do
      expect(supervisor_context).not_to receive(:stop)
      expect(supervised).not_to receive(:tell)

      expect(handle_failure).to eq(false)
    end
  end
end
