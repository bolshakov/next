# frozen_string_literal: true

RSpec.describe Next::Testing::Matchers::ExpectAllMessages, :actor_system do
  subject(:matcher) { described_class.new(expected_messages, timeout: 0.5) }

  let(:expected_messages) { ["Hi!", "How are you?"] }
  let(:echo) { system.actor_of(EchoActor.props) }

  it "passes when all expected messages are received" do
    echo.tell "How are you?"
    echo.tell "Hi!"

    expect(matcher.matches?(jailbreak: test_probe_jailbreak)).to eq(true)
  end

  it "fails when not all expected messages are received" do
    echo.tell "Hi!"

    expect(matcher.matches?(jailbreak: test_probe_jailbreak)).to eq(false)
    expect(matcher.failure_message).to eq(<<~MSG)
      expected collection contained:  ["Hi!", "How are you?"]
      actual collection contained:    ["Hi!"]
      the missing elements were:      ["How are you?"]
    MSG
  end
end
