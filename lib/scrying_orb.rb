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
require_relative 'model/channel'
require_relative 'model/node'
require_relative 'model/channel_list'
require_relative 'model/fowarding_history'
require_relative 'model/histogram_fee_report'
require_relative 'model/matrix_correlation_report'
require_relative 'cli/cli'
