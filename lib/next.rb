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

    def system(name, config = ConfigFactory.load, &configuration) = System.new(name, config, &configuration)

    # @api private
    def default_config
      current_directory = __dir__
      raise "Could not find current directory 🤷" unless current_directory

      Pathname(current_directory).join("next", "config.yml")
    end
  end
end

Signal.trap("INT") do
  Next::System.terminate_all!
  exit
end
