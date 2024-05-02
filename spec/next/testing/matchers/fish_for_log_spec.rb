# frozen_string_literal: true

RSpec.describe Next::Testing::Matchers::FishForLog, :actor_system do
  def fail_with(message)
    raise_error(RSpec::Expectations::ExpectationNotMetError, message)
  end

  context "when expected log without a level" do
    it "pass when the message matches" do
      system.log.info "Hi!"

      expect_log "Hi!"

      system.log.debug "How are you?"

      expect_log "How are you?"
    end

    it "fails when the message does not match" do
      system.log.info "Hi!"

      expect do
        expect_log "How are you?", timeout: 0.01
      end.to fail_with(<<~ERROR.strip)
        timeout (0.01) while waiting for log level=any message="How are you?".
        Received logs:
          * level=1 progname= message="Hi!"
      ERROR
    end
  end

  context "when expected log with a specific level" do
    it "pass when the message matches" do
      system.log.info "Hi!"

      expect_log "Hi!", level: :info

      system.log.debug "How are you?"

      expect_log "How are you?", level: :debug
    end

    it "fails when the message does not match" do
      system.log.info "Hi!"

      expect do
        expect_log "How are you?", level: :info, timeout: 0.01
      end.to fail_with(<<~ERROR.strip)
        timeout (0.01) while waiting for log level=info message="How are you?".
        Received logs:
          * level=1 progname= message="Hi!"
      ERROR
    end

    it "fails when the level does not match" do
      system.log.info "Hi!"

      expect do
        expect_log "How are you?", level: :debug, timeout: 0.01
      end.to fail_with(<<~ERROR.strip)
        timeout (0.01) while waiting for log level=debug message="How are you?".
        Received logs:
          * level=1 progname= message="Hi!"
      ERROR
    end
  end
end
