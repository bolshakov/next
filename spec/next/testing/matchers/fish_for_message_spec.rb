# frozen_string_literal: true

RSpec.describe Next::Testing::Matchers::FishForMessage, :actor_system do
  subject { matcher.matches?(jailbreak: test_probe_jailbreak) }

  let(:matcher) { described_class.new(expected_message, timeout: 0.5) }
  let(:echo) { system.actor_of(EchoActor.props) }

  context "when the expected message received right away" do
    let(:expected_message) { "Hi! Howe are you?" }

    it "matches" do
      echo.tell expected_message

      is_expected.to eq(true)
    end
  end

  context "when no message received " do
    let(:echo) { system.actor_of(EchoActor.props) }
    let(:expected_message) { "Hi! Howe are you?" }

    it "does not match" do
      is_expected.to eq(false)
      expect(matcher.failure_message).to eq(<<~MSG.strip)
        timeout (0.5) during fish_for_message while fishing for "Hi! Howe are you?".
      MSG
    end
  end

  context "when a different messages received" do
    let(:echo) { system.actor_of(EchoActor.props) }
    let(:expected_message) { "Hi! Howe are you?" }

    it "does not match" do
      echo.tell "Hi!"
      echo.tell "How are you?"

      is_expected.to eq(false)
      expect(matcher.failure_message).to eq(<<~MSG.strip)
        timeout (0.5) during fish_for_message while fishing for "Hi! Howe are you?".
        Received messages:
          * "Hi!"
          * "How are you?"
      MSG
    end
  end

  context "when an expected message is finally received" do
    let(:echo) { system.actor_of(EchoActor.props) }
    let(:expected_message) { "Hi! Howe are you?" }

    it "matches" do
      echo.tell "Hi!"
      echo.tell "How are you?"
      echo.tell expected_message

      is_expected.to eq(true)
      expect(matcher.actual_message).to eq(expected_message)
    end
  end
end
