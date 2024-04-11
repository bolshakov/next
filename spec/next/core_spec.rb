# frozen_string_literal: true

require "support/echo_actor"

RSpec.describe Next::Core, :actor_system do
  describe Next::PoisonPill, pending: true do
    let(:echo) { system.actor_of(EchoActor) }

    it "does not receive any messages after PoisonPill" do
      echo.tell :foo
      echo.tell Next::PoisonPill
      sleep 0.5

      # TODO: This behaviour has to be improved.
      #   It should be possible send a message to stopped actor
      echo.tell :bar

      expect_message(:foo)
      expect_no_message(timeout: 0.2)
    end
  end
end
