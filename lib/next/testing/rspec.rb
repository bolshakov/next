# frozen_string_literal: true

require "timeout"

RSpec.shared_context :actor_testing, :actor_system do
  include Next::Testing::Expectations

  let(:system) { Next.system("test-system") }

  let(:test_probe_props) { Next::Testing::TestActor.props(jailbreak: test_probe_jailbreak) }
  let(:test_probe_jailbreak) { Next::Testing::TestActor.jailbreak }
  let(:test_probe) { system.actor_of(test_probe_props, "test-probe") }

  let(:test_logs_listener_props) { Next::Testing::TestActor.props(jailbreak: test_logs_listener_jailbreak) }
  let(:test_logs_listener_jailbreak) { Next::Testing::TestActor.jailbreak }
  let(:test_logs_listener) { system.actor_of(test_logs_listener_props, "test-logs-listener") }

  around do |example|
    Next::LocalStorage.with_current_identity(test_probe) do
      example.run
    end
  end

  before do
    # Make sure async logging is started
    await_condition { system.log.is_a?(Next::Logging::AsyncLog) }

    system.event_stream.subscribe(test_logs_listener, Next::Logger::LogEvent)
  end

  after do
    system.terminate! unless system.terminated?
  end
end
