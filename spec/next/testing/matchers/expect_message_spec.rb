# frozen_string_literal: true

RSpec.describe Next::Testing::Matchers::ExpectMessage, :actor_system do
  let(:echo_actor) { system.actor_of(EchoActor.props) }

  def fail_with(message)
    raise_error(RSpec::Expectations::ExpectationNotMetError, message)
  end

  context "positive expectations" do
    subject { matcher.matches?(jailbreak: test_probe_jailbreak) }

    let(:matcher) { described_class.new(expected_message, timeout: 0.5) }

    context "when the actor receives the expected message" do
      let(:expected_message) { Fear.some("Hi! How are you?") }

      it "matches" do
        echo_actor.tell "Hi! How are you?"

        is_expected.to eq(true)
        expect(matcher.actual_message).to be_some_of("Hi! How are you?")
      end
    end

    context "when the actor receives a different message" do
      let(:expected_message) { Fear.some("How are you?") }

      it "does not match" do
        echo_actor.tell "Hi!"

        is_expected.to eq(false)
        expect(matcher.actual_message).to be_some_of("Hi!")
        expect(matcher.failure_message).to eq('expected to receive "How are you?", but got "Hi!"')
      end
    end

    context "when the actor receives no message" do
      let(:expected_message) { Fear.some("How are you?") }

      it "does not match" do
        is_expected.to eq(false)
        expect(matcher.actual_message).to be_none
        expect(matcher.failure_message).to eq('expected to receive "How are you?", but got nothing')
      end
    end
  end

  context "negative expectations" do
    subject { matcher.does_not_match?(jailbreak: test_probe_jailbreak) }

    let(:matcher) { described_class.new(expected_message, timeout: 0.5) }

    context "when the actor receives the unexpected message" do
      let(:expected_message) { Fear.some("Hi! How are you?") }

      it "does not match" do
        echo_actor.tell "Hi! How are you?"

        is_expected.to eq(false)
        expect(matcher).to have_attributes(
          actual_message: be_some_of("Hi! How are you?"),
          failure_message_when_negated: 'expected not to receive "Hi! How are you?", but got "Hi! How are you?"'
        )
      end
    end

    context "when the actor receives a message" do
      let(:expected_message) { Fear.none }

      it "does not match" do
        echo_actor.tell "Hi! How are you?"

        is_expected.to eq(false)
        expect(matcher).to have_attributes(
          actual_message: be_some_of("Hi! How are you?"),
          failure_message_when_negated: 'expected not to receive any message, but got "Hi! How are you?"'
        )
      end
    end

    context "when the actor receives no message" do
      let(:expected_message) { Fear.none }

      it "matches" do
        is_expected.to eq(true)
        expect(matcher.actual_message).to be_none
      end
    end

    context "when the block does not produce an unexpected message" do
      let(:expected_message) { Fear.some("Hi! How are you?") }

      it "matches" do
        is_expected.to eq(true)
        expect(matcher.actual_message).to be_none
      end
    end

    context "when the produced a different message" do
      let(:expected_message) { Fear.some("How are you?") }

      it "matches" do
        echo_actor.tell "Hi!"

        is_expected.to eq(true)
        expect(matcher.actual_message).to be_some_of("Hi!")
      end
    end
  end
end
