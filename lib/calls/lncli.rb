module ScryingOrb::Calls
  def self.lncli(*cmdline)
    call('lncli', *ScryingOrb::Configuration::Lncli.global_options, *cmdline)
  end

  def self.lncli_listchannels
    json_output(lncli(*%w[listchannels]))
  end

  def self.lncli_fwdinghistory(start_time:, end_time:, index_offset: 0, max_events: 1000)
    json_output(lncli(*%w[fwdinghistory], '--start_time', start_time.to_i.to_s, '-end_time', end_time.to_i.to_s, '--index_offset', index_offset.to_s, '--max_events', max_events.to_s, '--skip_peer_alias_lookup'))
  end
end
