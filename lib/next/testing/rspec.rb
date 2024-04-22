# frozen_string_literal: true

require "timeout"

RSpec.shared_context :actor_testing, :actor_system do
  # include Next::Actor::Testing
  include Next::Testing::Expectations

  let(:jailbreak) { Next::Testing::TestActor.jailbreak }
  let(:system) { Next.system("test-system") }
  let(:test_actor) do
    props = Next::Testing::TestActor.props(jailbreak:)
    system.actor_of(props, "TestActor-" + SecureRandom.uuid)
  end

  around do |example|
    Next::LocalStorage.with_current_identity(test_actor) do
      example.run
    end
  end

  after do
    jailbreak.stop
    system.terminate
    system.await_termination
  end
end
