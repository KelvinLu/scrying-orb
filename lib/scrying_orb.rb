require 'logger'

class ScryingOrb
  @logger = Logger.new(STDERR).tap do |logger|
    logger.level =
      if ENV['DEBUG'] == 'true'
        Logger::DEBUG
      else
        Logger::WARN
      end
  end

  def self.log
    @logger
  end
end

require_relative 'calls/command'
require_relative 'configuration/configuration'
require_relative 'cli/cli'
