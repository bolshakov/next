# frozen_string_literal: true

require "timeout"

RSpec.shared_context :actor_testing, :actor_system do
  include Next::Testing::Expectations

  let(:system) { Next.system("test-system") }
  let(:test_probe_props) { Next::Testing::TestActor.props(jailbreak: test_probe_jailbreak) }
  let(:test_probe_jailbreak) { Next::Testing::TestActor.jailbreak }
  let(:test_probe) { system.actor_of(test_probe_props, "test-actor-" + SecureRandom.uuid) }

  around do |example|
    Next::LocalStorage.with_current_identity(test_probe) do
      example.run
    end
  end

  after do
    test_probe_jailbreak.stop
    system.terminate
    system.await_termination
  end
end
