require 'time'

class ScryingOrb::Command::FeeReport
  include ScryingOrb::Command

  command 'fee-report'

  calling_convention(0..1) do
    self.banner = 'Usage: fee-report [options] [channel ID]'

    self.on('--node-alias=NAME', 'Match by node alias, where the name may be a partial match') do |name|
      options[:node_alias] = name
    end

    self.on('--node-pubkey=PUBLIC_KEY', 'Match by node public key, where the key may be a matching prefix') do |pubkey|
      options[:node_pubkey] = pubkey
    end

    self.on('--chanpoint=NAME', 'Match by channel point (<txid[:index]>), where txid may simply be a matching prefix') do |name|
      options[:chanpoint] = name
    end

    self.on('--time-range-start=DATE', 'Start of the time range, expressed as a parseable date (default: one week prior to the end date)') do |date|
      options[:start_time] = Time.parse(date)
    end

    self.on('--time-range-end=DATE', 'End of the time range, expressed as a parseable date (default: now)') do |date|
      options[:end_time] = Time.parse(date)
    end

    self.on('--show-corresponding-nodes=N', 'Limit the number of corresponding nodes shown (default: 5)', Integer) do |number|
      options[:show_corresponding_nodes] = number
    end
  end

  run do |options:, arguments:|
    end_time = options.fetch(:end_time, Time.now)
    start_time = options.fetch(:start_time, end_time - 604800)

    if start_time > end_time
      ScryingOrb.log.error { 'start date is after end date' }
      exit 2
    end

    channel_list = ScryingOrb::ChannelList.new

    channels = channel_list.channel_lookup(
      by_alias:     options[:node_alias],
      by_pubkey:    options[:node_pubkey],
      by_chanpoint: options[:chanpoint],
    )

    channel_id = arguments.first

    channel =
      if channel_id.nil?
        if channels.empty?
          ScryingOrb.log.warn { 'no channels found' }
          exit 2
        elsif channels.count > 1
          ScryingOrb.log.warn { "more than one channel found; #{channels.map { |channel| channel.id }.join(', ')}" }
          exit 2
        end

        channels.first
      else
        channels = channels.select { |channel| channel.id == channel_id }

        if channels.empty?
          ScryingOrb.log.warn { 'no channels found' }
          exit 2
        end

        channels.first
      end

    report = ScryingOrb::HistogramFeeReport.new(
      start_time: start_time,
      end_time: end_time,
      channel_list: channel_list,
      channel: channel,
      show_corresponding_nodes: options[:show_corresponding_nodes] || 5,
    )

    report.display
  end
end
