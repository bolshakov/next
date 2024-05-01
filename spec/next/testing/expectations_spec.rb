# frozen_string_literal: true

RSpec.describe Next::Testing::Expectations, :actor_system do
  let(:echo_actor) { system.actor_of(EchoActor.props) }

  def fail_with(message)
    raise_error(RSpec::Expectations::ExpectationNotMetError, message)
  end

  describe "#expect_message" do
    it "passes when expected message is received" do
      echo_actor.tell "Hi! How are you?"

      expect_message "Hi! How are you?"
    end

    it "fails when expected message is not received" do
      echo_actor.tell "Hi! How are you?"

      expect do
        expect_message "Hi!"
      end.to fail_with('expected to receive "Hi!", but got "Hi! How are you?"')
    end

    it "fails when expected a message bun nothing received" do
      expect do
        expect_message "Hi!", timeout: 0.01
      end.to fail_with('expected to receive "Hi!", but got nothing')
    end
  end

  describe "#expect_no_message" do
    it "fails when expected message is received" do
      echo_actor.tell "Hi! How are you?"

      expect do
        expect_no_message
      end.to fail_with('expected not to receive any message, but got "Hi! How are you?"')
    end

    it "passes when no message received" do
      expect do
        expect_no_message(timeout: 0.01)
      end.not_to raise_error
    end
  end

  describe "#await_condition" do
    it "fails when condition never met" do
      expect do
        await_condition(timeout: 0.01) {}
      end.to fail_with("timout (0.01) expired: condition is not met")
    end

    it "fails when condition never met with custom message" do
      expect do
        await_condition(timeout: 0.01, message: "whops") {}
      end.to fail_with("timout (0.01) expired: whops")
    end

    context "when condition eventually satisfied" do
      let(:cond) do
        counter = 2

        proc do
          counter -= 1
          counter.zero?
        end
      end

      it "passes" do
        await_condition(interval: 0.0001, timeout: 0.01, message: "whops") { cond.call }
      end
    end
  end
end
