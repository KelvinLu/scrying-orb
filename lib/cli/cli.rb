require_relative 'colors'
require_relative '../command/command'

class ScryingOrb::CLI
  def self.start
    ScryingOrb::Command.start_command
  end
end
