class ScryingOrb::Command::LookupChannels
  include ScryingOrb::Command

  command 'lookup-channels'

  calling_convention(0) do
    self.banner = 'Usage: lookup-channels [options]'

    self.on('--node-alias=NAME', 'Match by node alias, where the name may be a partial match') do |name|
      options[:node_alias] = name
    end

    self.on('--node-pubkey=PUBLIC_KEY', 'Match by node public key, where the key may be a matching prefix') do |pubkey|
      options[:node_pubkey] = pubkey
    end

    self.on('--chanpoint=NAME', 'Match by channel point (<txid[:index]>), where txid may simply be a matching prefix') do |name|
      options[:chanpoint] = name
    end
  end

  run do |options:, arguments:|
    channels = ScryingOrb::ChannelList.new.channel_lookup(
      by_alias:     options[:node_alias],
      by_pubkey:    options[:node_pubkey],
      by_chanpoint: options[:chanpoint],
    )

    if channels.empty?
      ScryingOrb.log.warn { 'no channels found' }
      exit 2
    end

    channels.each do |channel|
      node_display = channel.node.alias&.magenta.bold || channel.node.pubkey.magenta.italic
      puts "#{channel.id.bold} | #{channel.txid.blue}:#{channel.txid_index.to_s.cyan} | #{node_display}"
    end
  end
end
