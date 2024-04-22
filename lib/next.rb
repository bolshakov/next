# frozen_string_literal: true

require "zeitwerk"
require "concurrent"
require "fear"

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

    def system(name) = System.new(name)
  end
end

Signal.trap("INT") do
  Next::System.terminate_all!
  exit
end
