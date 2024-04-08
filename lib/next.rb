# frozen_string_literal: true

require "zeitwerk"
require "concurrent"

loader = Zeitwerk::Loader.for_gem
loader.setup

module Next
  class << self
    def props(actor_class, **attributes)
      Props.new(actor_class, **attributes)
    end

    def default_executor
      Concurrent.global_io_executor
    end
  end

  module AutoReceivedMessage
  end

  PoisonPill = Object.new.extend(AutoReceivedMessage)
  Terminate = Object.new.extend(SystemMessage)
end
