# frozen_string_literal: true

RSpec.describe Next::Logger, :actor_system do
  let(:logger_ref) { system.actor_of(props) }
  let(:props) { Next.props(described_class, logger:) }
  let(:logger) { instance_double(Logger) }

  shared_examples Next::Logger do |log_event|
    context "when an event with `#{log_event.level}` severity received" do
      after do
        logger_ref.tell Next::PoisonPill
        Fear::Await.result(logger_ref.termination_future, 3)
      end

      it "calls Logger#add with the giver serverity" do
        expect(logger).to receive(:add).with(log_event.level, log_event.message, log_event.progname)

        logger_ref.tell log_event
      end
    end
  end

  include_examples Next::Logger, Next::Logger::Info.new(message: "Hi!", progname: "Next::Actor")
  include_examples Next::Logger, Next::Logger::Debug.new(message: "Hi!", progname: "Next::Actor")
  include_examples Next::Logger, Next::Logger::Warn.new(message: [], progname: "Next::Actor")
  include_examples Next::Logger, Next::Logger::Error.new(message: StandardError.new, progname: "Next::Actor")
  include_examples Next::Logger, Next::Logger::Fatal.new(message: "Hi!", progname: "Next::Actor")
  include_examples Next::Logger, Next::Logger::Unknown.new(message: "Hi!", progname: "Next::Actor")
end
