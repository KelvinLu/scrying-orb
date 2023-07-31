class ScryingOrb::Command::CorrelationMatrix
  include ScryingOrb::Command

  command 'correlation-matrix'

  calling_convention(0) do
    self.banner = 'Usage: correlation-matrix [options]'

    self.on('--time-range-start=DATE', 'Start of the time range, expressed as a parseable date (default: one week prior to the end date)') do |date|
      options[:start_time] = Time.parse(date)
    end

    self.on('--time-range-end=DATE', 'End of the time range, expressed as a parseable date (default: now)') do |date|
      options[:end_time] = Time.parse(date)
    end

    self.on('--show-nodes=N', 'Limit the number of nodes shown (default: 30)', Integer) do |number|
      options[:show_nodes] = number
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

    report = ScryingOrb::MatrixCorrelationReport.new(
      start_time: start_time,
      end_time: end_time,
      channel_list: channel_list,
      show_nodes: options[:show_nodes] || 30,
    )

    report.display
  end
end
