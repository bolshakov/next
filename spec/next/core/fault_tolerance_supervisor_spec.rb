# frozen_string_literal: true

require "support/supervision"

RSpec.describe Next::Core::FaultTolerance, :actor_system do
  let(:supervisor_strategy_class) do
    Class.new(Next::SupervisorStrategy) do
      attr_reader :handling_result

      def initialize(handling_result)
        @handling_result = handling_result
      end

      def handle_failure(**)
        handling_result
      end
    end
  end

  let(:spying_supervisor_strategy_class) do
    Class.new(Next::SupervisorStrategy) do
      attr_reader :spy

      def initialize(spy)
        @spy = spy
      end

      def handle_failure(cause:, child:, **)
        spy.tell([child, cause])
        true
      end
    end
  end

  # This is the main actor under test. We test its supervision logic here
  let(:supervisor) { supervisors_supervisor.ask!([:create_supervised, supervisor_props]).get }
  let(:supervisor_props) { SupervisionTestingActor.props(supervisor_strategy) }
  let(:supervisor_strategy) { supervisor_strategy_class.new(handling_result) }

  # The sole purpose of this actor is to test escalation path of the +supervisor+
  let(:supervisors_supervisor) { system.actor_of(supervisors_supervisor_props, "supervisor's supervisor") }
  let(:supervisors_supervisor_props) { SupervisionTestingActor.props(spying_supervisor_strategy) }
  let(:spying_supervisor_strategy) { spying_supervisor_strategy_class.new(test_probe) }

  context "when SystemMessages::Failed received" do
    let(:error) { NoMethodError.new(error_message) }
    let(:error_message) { "something went wrong" }

    context "when the subject is a child of supervisor" do
      let(:supervised) { supervisor.ask!([:create_supervised, supervised_props]).get }
      let(:supervised_props) { SupervisionTestingActor.props }

      context "when the failure has been handled" do
        let(:handling_result) { true }

        it "does not escalate failure" do
          supervisor.tell Next::SystemMessages::Failed.new(child: supervised, cause: error)

          expect_no_message(timeout: 0.2)
        end
      end

      context "when the failure has not been handled" do
        let(:handling_result) { false }

        it "escalates failure to its supervisor" do
          supervisor.tell Next::SystemMessages::Failed.new(child: supervised, cause: error)

          expect_message(
            [
              be(supervisor),
              be_kind_of(NoMethodError).and(have_attributes(message: error_message))
            ],
            timeout: 1
          )
        end
      end
    end

    context "when the subject is not a child of supervisor" do
      let(:failing_actor) { system.actor_of(failing_actor_props) }
      let(:failing_actor_props) { SupervisionTestingActor.props }

      context "when the failure could be handled", skip: "nothing to test so far" do
        let(:handling_result) { true }
      end

      context "when the failure could not be handled" do
        let(:handling_result) { false }

        it "does not escalate failure to its supervisor" do
          supervisor.tell(Next::SystemMessages::Failed.new(child: failing_actor, cause: error))

          expect_no_message(timeout: 0.2)
        end
      end
    end
  end
end
