# frozen_string_literal: true

require "support/actor_with_inspector"

RSpec.describe Next::Actor, :actor_system do
  describe "#pre_start" do
    let(:actor) { system.actor_of(actor_class.props) }
    let(:actor_class) do
      Class.new(ActorWithInspector) do
        def initialize(...)
          super
          inspector << "Hello from #initializer"
        end

        def pre_start
          inspector << "Hello from #pre_start"
        end
      end
    end

    it "receives message sent from the initializer, then from pre_start" do
      actor << "after start"

      expect_message("Hello from #initializer")
      expect_message("Hello from #pre_start")
      expect_message("after start")
    end

    context "when initializer fails" do
      let(:actor_class) do
        Class.new(ActorWithInspector) do
          def initialize(...)
            super
            raise
          end

          def pre_start
            inspector << "Hello from #pre_start"
          end
        end
      end

      it "does not execute #pre_start hook" do
        expect_no_message(timeout: 0.5)
      end
    end
  end

  describe "#post_stop" do
    let(:actor) { system.actor_of(actor_class.props) }
    let(:actor_class) do
      Class.new(ActorWithInspector) do
        def post_stop
          inspector << "Hello from #post_stop"
        end
      end
    end

    context "when actor receives PoisonPill" do
      it "runs #post_stop callback" do
        actor << "before stop"
        actor << Next::PoisonPill

        expect_message("before stop")
        expect_message("Hello from #post_stop")
      end
    end
  end

  describe "#pre_restart" do
    subject!(:actor) { system.actor_of(actor_class.props) }

    before do
      # ensure actor has started
      actor << "ping"
      expect_message("ping")
    end

    context "when Next::SystemMessages::Recreate received" do
      let(:actor_class) do
        Class.new(ActorWithInspector) do
          def pre_restart(reason:, **)
            inspector << "Hello from #pre_restart, reason class: #{reason.class}"
          end
        end
      end

      it "executes #pre_restart before starting a new instance" do
        actor << Next::SystemMessages::Recreate.new(NameError.new)

        expect_message("Hello from #pre_restart, reason class: NameError")
      end
    end

    describe "default implementation" do
      let(:actor_class) do
        Class.new(ActorWithInspector) do
          def post_stop
            inspector << "Hello from #post_stop"
          end
        end
      end

      it "executes #post_stop hook" do
        actor << Next::SystemMessages::Recreate.new(StandardError.new)

        expect_message("Hello from #post_stop")
      end
    end
  end

  describe "#post_restart" do
    subject!(:actor) { system.actor_of(actor_class.props) }

    context "when Next::SystemMessages::Recreate received" do
      let(:actor_class) do
        Class.new(ActorWithInspector) do
          def post_restart(reason:, **)
            inspector << "Hello from #post_restart, reason class: #{reason.class}"
          end
        end
      end

      before do
        # ensure actor has started
        actor << "ping"
        fish_for_message("ping")
      end

      it "executes #post_restart on a new instance" do
        actor << Next::SystemMessages::Recreate.new(NameError.new)

        expect_message("Hello from #post_restart, reason class: NameError")
      end
    end

    describe "default implementation" do
      let(:actor_class) do
        Class.new(ActorWithInspector) do
          def pre_start
            inspector << "Hello from #pre_start object_id=#{__id__}"
          end
        end
      end

      def object_id
        expect_message { |message| /Hello from #pre_start/.match?(message) }.split("object_id=").last
      end

      it "executes #pre_start hook" do
        object_id_before_recreate = object_id

        actor << Next::SystemMessages::Recreate.new(StandardError.new)

        expect(object_id).not_to eq(object_id_before_recreate), "should instantiate a new actor"

        expect_no_message(timeout: 0.5)
      end
    end
  end
end
