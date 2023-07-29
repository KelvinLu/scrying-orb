require 'json'

module ScryingOrb::Calls
  def self.call(*cmdline)
    ScryingOrb.log.info("Calling command line: #{cmdline.inspect}")

    io = IO.popen(cmdline)
    io.read.tap do
      io.close
      raise 'Command failed' unless $?.success?
    end
  end

  def self.json_output(output)
    JSON.load(output)
  end
end

require_relative 'lncli'
