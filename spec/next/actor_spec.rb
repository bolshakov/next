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
end
