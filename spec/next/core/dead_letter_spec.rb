# frozen_string_liter: true

RSpec.describe Next::DeadLetter, :actor_system do
  let(:actor_ref) { system.actor_of(props, "dead-letters-test") }
  let(:props) { actor_class.props }
  let(:message) { "Test message" }
  let(:system) { Next.system("test-system", config) }
  let(:config) do
    Next::ConfigFactory.new.load(
      next: {
        stdout_log_level: "debug",
        debug: {
          receive: true,
          unhandled: true
        }
      }
    )
  end

  before do
    system.event_stream.subscribe(test_probe, Next::DeadLetter)
  end

  context "when a #receive does not handle the message" do
    let(:actor_class) do
      Class.new(ActorWithInspector) do
        def receive(message)
          case message
          in :hit
            # noop
          end
        end
      end
    end

    it "routes to Dead Letters" do
      actor_ref.tell message

      expect_message(Next::DeadLetter.new(sender: test_probe, recipient: actor_ref, message:))
    end
  end

  context "when the message is explicitly passed" do
    let(:actor_class) do
      Class.new(ActorWithInspector) do
        def receive(message)
          case message
          in "Test message"
            pass
          end
        end
      end
    end

    it "routes to Dead Letters" do
      actor_ref.tell message

      expect_message(Next::DeadLetter.new(sender: test_probe, recipient: actor_ref, message:))
    end
  end

  context "when the actor is terminated" do
    let(:actor_class) { Class.new(ActorWithInspector) }

    it "routes to Dead Letters" do
      actor_ref.tell Next::PoisonPill
      await_condition { actor_ref.terminated? }

      actor_ref.tell message

      expect_message(Next::DeadLetter.new(sender: test_probe, recipient: actor_ref, message:), timeout: 0.1)
    end
  end

  context "when message is send but by the time of delivery the actor is terminated" do
    let(:latch) { Concurrent::CountDownLatch.new(1) }
    let(:props) { actor_class.props(latch:) }
    let(:actor_class) do
      Class.new(ActorWithInspector) do
        def self.props(latch:) = Next.props(self, latch:)

        def initialize(latch:)
          @latch = latch
        end

        def receive(message)
          case message
          in "terminate"
            @latch.wait
            identity << Next::SystemMessages::Terminate
          in "Test message A"
            # noop
          end
        end
      end
    end

    it "routes to Dead Letters" do
      actor_ref.tell "terminate"
      actor_ref.tell "Test message A"
      actor_ref.tell "Test message B"
      actor_ref.ask "Test message C"

      latch.count_down

      expect_message(Next::DeadLetter.new(sender: test_probe, recipient: actor_ref, message: "Test message A"), timeout: 0.1)
      expect_message(Next::DeadLetter.new(sender: test_probe, recipient: actor_ref, message: "Test message B"), timeout: 0.1)
      expect_message(be_kind_of(Next::DeadLetter).and(have_attributes(recipient: actor_ref, message: "Test message C")), timeout: 0.1)
    end
  end
end
