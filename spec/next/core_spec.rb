# frozen_string_literal: true

require "support/echo_actor"

RSpec.describe Next::Core, :actor_system do
  describe Next::PoisonPill do
    let(:echo) { system.actor_of(EchoActor.props) }

    it "does not receive any messages after PoisonPill" do
      echo.tell :foo
      echo.tell Next::PoisonPill
      echo.tell :bar

      expect_message(:foo)
      expect_no_message(timeout: 0.2)
    end
  end
end
