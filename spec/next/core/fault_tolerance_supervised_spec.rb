# frozen_string_literal: true

require "support/supervision"

RSpec.describe Next::Core::FaultTolerance, :actor_system do
  let(:failure_flag) { nil }
  let(:supervised) { supervisor.ask!([:create_supervised, supervised_props]).get }
  let(:supervisor_props) { SupervisionTestingActor.props(supervision_strategy) }
  let(:supervised_props) { SupervisionTestingActor.props }
  let(:supervisor) { system.actor_of(supervisor_props, "supervisor") }
  let(:supervision_strategy) { TestingSupervisionStrategy.new }

  context "when error happens during initialization" do
    let(:failure_flag) { system.actor_of(FeatureFlag.props(true)) }
    let(:supervised_props) { SupervisionTestingActor.props(nil, failure_flag) }

    it "does not process any messages" do
      expect(supervised.ask!(:counter, timeout: 0.2)).to be_none
    end
  end

  context "when error happens during processing" do
    it "stops processing messages" do
      expect(supervised.ask!(:counter)).to be_some_of(1)

      supervised.tell :fail

      expect(supervised.ask!(:counter, timeout: 0.1)).to be_none
    end

    it "children also stops processing messages" do
      child_of_supervised = supervised.ask!([:create_supervised, SupervisionTestingActor.props]).get

      expect(child_of_supervised.ask!(:counter)).to be_some_of(1)

      supervised.tell :fail

      await_condition do
        child_of_supervised.ask!(:counter, timeout: 0.1) == Fear::None
      end
    end

    it "children of child also stops processing messages" do
      child_of_supervised_child = supervised
        .ask!([:create_supervised, SupervisionTestingActor.props]).get
        .ask!([:create_supervised, SupervisionTestingActor.props]).get

      expect(child_of_supervised_child.ask!(:counter)).to be_some_of(1)

      supervised.tell :fail

      await_condition do
        child_of_supervised_child.ask!(:counter, timeout: 0.1) == Fear::None
      end
    end
  end

  context "when supervised is suspended" do
    context "when SystemMessages::Recreate received" do
      it "recreates supervised and drops its state" do
        expect(supervised.ask!(:counter)).to be_some_of(1)

        supervised.ask! :increment
        supervised.ask! :increment

        expect(supervised.ask!(:counter)).to be_some_of(3)

        supervised.tell :fail

        supervised.tell(Next::SystemMessages::Recreate.new(NoMethodError.new))

        await_condition do
          supervised.ask!(:counter, timeout: 0.1).include?(1)
        end
      end

      context "when error happens in the initializer" do
        let(:failure_flag) { system.actor_of(FeatureFlag.props(true)) }
        let(:supervised_props) { SupervisionTestingActor.props(nil, failure_flag) }

        it "recreates the supervised" do
          # Ensure supervised has failed
          supervised
          # Ensure supervisor is ready to supervise
          supervisor.ask! :counter

          # Don't fail on the recreation
          failure_flag.ask! false
          supervised.tell Next::SystemMessages::Recreate.new(NoMethodError.new)

          # Finally supervised has been created
          expect(supervised.ask!(:counter)).to be_some_of(1)
        end
      end

      context "when supervised has children" do
        it "recreates the supervised and thus loose child's states" do
          child_of_supervised = supervised.ask!([:create_supervised, SupervisionTestingActor.props]).get

          expect(child_of_supervised.ask!(:counter)).to be_some_of(1)

          child_of_supervised.ask! :increment
          child_of_supervised.ask! :increment

          supervised.tell :fail

          supervised.tell Next::SystemMessages::Recreate.new(NoMethodError.new)

          await_condition do
            child_of_supervised.ask!(:counter, timeout: 0.1) == Fear::None
          end
        end
      end
    end

    context "when SystemMessages::Resume received" do
      it "continues processing messages" do
        expect(supervised.ask!(:counter)).to be_some_of(1)

        supervised.ask! :increment
        supervised.ask! :increment

        supervised.tell :fail

        supervised.tell Next::SystemMessages::Resume.new(NoMethodError.new)
        expect(supervised.ask!(:counter)).to be_some_of(3)
      end

      context "when error happens in the initializer" do
        let(:failure_flag) { system.actor_of(FeatureFlag.props(true)) }
        let(:supervised_props) { SupervisionTestingActor.props(nil, failure_flag) }

        it "recreates the supervised" do
          # Ensure supervised has failed
          supervised
          # Ensure supervisor is ready to supervise
          supervisor.ask! :counter

          # Don't fail on the recreation
          failure_flag.ask! false
          supervised.tell Next::SystemMessages::Resume.new(NoMethodError.new)

          expect(supervised.ask!(:counter)).to be_some_of(1)
        end
      end

      context "when supervised has children" do
        it "they continue processing messages as well" do
          child_of_supervised = supervised.ask!([:create_supervised, SupervisionTestingActor.props]).get

          expect(child_of_supervised.ask!(:counter)).to be_some_of(1)

          child_of_supervised.ask! :increment
          child_of_supervised.ask! :increment

          supervised.tell :fail

          supervised.tell Next::SystemMessages::Resume.new(NoMethodError.new)

          expect(child_of_supervised.ask!(:counter)).to be_some_of(3)
        end
      end
    end

    context "when SystemMessages::Terminate received" do
      it "terminates the supervised" do
        supervised.tell :fail

        supervised.tell Next::SystemMessages::Terminate

        await_condition do
          supervisor.ask!([:find_supervised, supervised.name], timeout: 0.1).include?(Fear::None)
        end
      end

      context "when error happens in the initializer" do
        let(:failure_flag) { system.actor_of(FeatureFlag.props(true)) }
        let(:supervised_props) { SupervisionTestingActor.props(nil, failure_flag) }

        it "terminates the supervised" do
          # Ensure supervised has failed
          supervised

          supervised.tell Next::SystemMessages::Terminate

          await_condition do
            supervisor.ask!([:find_supervised, supervised.name], timeout: 0.1).include?(Fear::None)
          end
        end
      end

      context "when supervised has children" do
        it "terminates them all" do
          child_of_supervised = supervised.ask!([:create_supervised, SupervisionTestingActor.props]).get

          expect(child_of_supervised.ask!(:counter)).to be_some_of(1)

          supervised.tell :fail

          supervised.tell Next::SystemMessages::Terminate

          expect(child_of_supervised.ask!(:counter, timeout: 0.1)).to be_none
        end
      end
    end
  end
end
