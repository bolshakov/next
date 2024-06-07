# frozen_string_literal: true

require "configx"

module Next
  # 'Loads' config in the following order:
  #   1. Reads default config
  #   2. Reads all the config files provided in the order
  #   3. Reads environment variables
  class ConfigFactory < ConfigX::ConfigFactory
    class << self
      def default_env_prefix = "NEXT"

      def default_dir_name = "next"

      def default_file_name = "next"
    end

    private

    def sources
      [Next.default_config, *super]
    end
  end
end
