# frozen_string_literal: true

RSpec.describe Next::ConfigFactory do
  shared_examples "option with default" do |option, default:|
    describe "Next::ConfigFactory##{option}" do
      context "when value is not provided" do
        subject { config_factory.__send__(option) }

        let(:config_factory) { described_class.new }

        it "fallbacks to default value `#{default}`" do
          is_expected.to eq(default)
        end
      end
    end
  end

  include_examples "option with default", :env, default: "production"
  include_examples "option with default", :env_prefix, default: "NEXT"
  include_examples "option with default", :env_separator, default: "__"
  include_examples "option with default", :dir_name, default: "next"
  include_examples "option with default", :file_name, default: "next"

  describe ".load" do
    context "when no config files supplied" do
      subject(:config) { described_class.load.next }

      it "loads default config" do
        is_expected.to have_attributes(
          logger: "stdout",
          stdout_log_level: "warn",
          debug: have_attributes(
            receive: false,
            autoreceive: false,
            unhandled: false,
            lifecycle: false
          )
        )
      end
    end

    context "when config files are present" do
      subject(:config_factory) do
        described_class.new(
          "development",
          config_root: "spec/support/config"
        ).load
      end

      around do |example|
        next__three = ENV["NEXT__THREE"]
        ENV["NEXT__THREE"] = "environment variable"
        example.run
        ENV["NEXT__THREE"] = next__three
      end

      it "loads config files in order" do
        is_expected.to have_attributes(
          one: "next/development.local.yml",
          two: "next/development.local.yml",
          three: "environment variable",
          four: "next.local.yml",
          five: "next/development.yml",
          six: "next.yml"
        )
      end
    end
  end
end
