require 'yaml'

module ScryingOrb::Configuration
  def self.included(base)
    base.extend ConfigurationFile
  end

  module ConfigurationFile
    attr_reader :filepath, :configuration

    @filepath = nil
    @configuration = nil

    def file(filepath)
      configuration_dir = ENV['CONFIGURATION_DIR'] || File.join(
        File.dirname(__FILE__), '../../configuration'
      )

      filepath = File.join(configuration_dir, filepath)
      raise "file at #{filepath} not found" unless File.exist?(filepath)

      @filepath = filepath
      @configuration = YAML.safe_load(File.read(filepath))
    end
  end
end

require_relative './lncli'
