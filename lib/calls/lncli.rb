module ScryingOrb::Calls
  def self.lncli(*cmdline)
    call('lncli', *ScryingOrb::Configuration::Lncli.global_options, *cmdline)
  end
end
