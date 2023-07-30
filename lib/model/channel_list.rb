class ScryingOrb::ChannelList
  attr_reader :nodes, :channels

  def initialize
    @nodes, @channels = self.class.from_listchannels(ScryingOrb::Calls.lncli_listchannels)
    @nodes.freeze
    @channels.freeze
  end

  def channel(id)
    channels.select { |channel| channel.id == id }.first
  end

  def channel_lookup(by_alias: nil, by_pubkey: nil, by_chanpoint: nil)
    result = channels.dup

    unless by_alias.nil?
      result.filter! do |channel|
        node_alias = channel.node.alias
        node_alias.nil? ? false : node_alias.include?(by_alias)
      end
    end

    unless by_pubkey.nil?
      result.filter! { |channel| channel.node.pubkey.start_with?(by_pubkey) }
    end

    unless by_chanpoint.nil?
      txid_prefix, txid_index = by_chanpoint.split(':')
      txid_index = txid_index&.to_i

      result.filter! do |channel|
        channel.txid.start_with?(txid_prefix) && (txid_index.nil? ? true : channel.txid_index == txid_index)
      end
    end

    result
  end

  def self.from_listchannels(output)
    nodes = {}

    channels =
      output.fetch('channels').map do |channel|
        txid, txid_index = channel.fetch('channel_point').split(':')
        txid_index = txid_index.to_i

        node_pubkey = channel.fetch('remote_pubkey')

        node =
          if nodes.key?(node_pubkey)
            nodes.fetch(node_pubkey)
          else
            nodes[node_pubkey] = ScryingOrb::Node.new(
              node_pubkey,
              node_alias: channel.fetch('peer_alias', nil)
            )
          end

        ScryingOrb::Channel.new(
          id:           channel.fetch('chan_id'),
          txid:         txid,
          txid_index:   txid_index,

          node:         node,

          details:      channel
        )
      end

    [nodes.values, channels]
  end
end
