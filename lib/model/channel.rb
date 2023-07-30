class ScryingOrb::Channel
  attr_reader :id, :txid, :txid_index, :node

  def initialize(id:, txid:, txid_index:, node:, details:)
    @id         = id
    @txid       = txid
    @txid_index = txid_index

    @node       = node

    @details    = details
  end

  def capacity
    @details.fetch('capacity').to_i
  end

  def balance_ratio
    local_balance / (local_balance + remote_balance).to_f
  end

  def local_balance
    @details.fetch('local_balance').to_i
  end

  def remote_balance
    @details.fetch('remote_balance').to_i
  end

  def uptime_days
    @details.fetch('uptime').to_i / 86400.0
  end

  def total_satoshis_sent
    @details.fetch('total_satoshis_sent').to_i
  end

  def total_satoshis_received
    @details.fetch('total_satoshis_received').to_i
  end
end
