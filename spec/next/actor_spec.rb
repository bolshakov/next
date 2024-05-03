# frozen_string_literal: true

require "support/echo_actor"
require "support/actor_with_inspector"

RSpec.describe Next::Actor, :actor_system do
  describe "#sender" do
    let(:echo) { system.actor_of(EchoActor.props) }

    it "sends back messages unchanged" do
      echo.tell "How are you?"

      expect_message("How are you?")
    end
  end

  context "when actor sends message to itself" do
    let(:actor_class) do
      Class.new(ActorWithInspector) do
        def receive(message)
          if message == :send_to_self
            super
            identity << :sent_to_self
          else
            super
          end
        end
      end
    end
    let(:actor) { system.actor_of(actor_class.props, "echo") }

    it "receives this message" do
      actor.tell :send_to_self

      expect_message(:send_to_self)
      expect_message(:sent_to_self)
    end
  end

  context "when actor sends message to itself from the initializer" do
    let(:actor_class) do
      Class.new(ActorWithInspector) do
        def initialize(...)
          super
          identity << "Hello from the initializer"
        end
      end
    end
    let(:actor) { system.actor_of(actor_class.props, "echo") }

    it "receives message sent from the initializer" do
      actor.tell "Second message"

      # The order is not guaranteed
      expect_all_messages("Hello from the initializer", "Second message")
    end
  end

  context "when a NoMatchingPatternError exception is thrown" do
    let(:system) do
      Next.system("test") do |config|
        config.debug.unhandled = true
      end
    end

    let(:actor_class) do
      Class.new(ActorWithInspector) do
        def receive(message)
          case message
          in :deeper
            deeper(message)
          end
        end

        private def deeper(message)
          case message
          in :test
          end
        end

        def post_restart(reason:)
          inspector << ["restarted", reason]
        end
      end
    end

    before do
      system.event_stream.subscribe(test_probe, Next::DeadLetter)
    end

    context "from the #receive method" do
      let(:message) { "Test message" }

      it "considers message unhandled and does not restart an actor" do
        actor = system.actor_of(actor_class.props)
        actor.tell message

        expect_log(/received unhandled message/, level: :debug)
        expect_message(Next::DeadLetter.new(sender: test_probe, recipient: actor, message:))
        expect_no_message(timeout: 0.1)
      end
    end

    context "from the method that #receive calls" do
      it "raises NoMatchingPatternError and consider method handled" do
        actor = system.actor_of(actor_class.props)
        actor.tell :deeper

        expect_log(be_kind_of(NoMatchingPatternError), level: :error)
        expect_no_log(/received unhandled message/, timeout: 0.1)
        expect_message ["restarted", be_kind_of(NoMatchingPatternError)]
        expect_no_message timeout: 0.1
      end
    end
  end
end
