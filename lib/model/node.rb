class ScryingOrb::Node
  attr_reader :pubkey, :alias

  def initialize(node_pubkey, node_alias: nil)
    @pubkey = node_pubkey
    @alias  = node_alias
  end
end
