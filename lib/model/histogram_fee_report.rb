class ScryingOrb::HistogramFeeReport
  def initialize(start_time:, end_time:, channel_list:, channel:, show_corresponding_nodes: 5)
    @start_time = start_time
    @end_time   = end_time

    @channel_list = channel_list
    @channel      = channel

    @fwdinghistory = ScryingOrb::ForwardingHistory.new(start_time: start_time, end_time: end_time, channel_list: channel_list).history

    @show_corresponding_nodes = show_corresponding_nodes

    calculate
  end

  def calculation(key)
    @calculations.fetch(key)
  end

  def calculate
    @calculations = {}

    forwarding_out  = @fwdinghistory.select { |f| f.channel_out == @channel }
    forwarding_in   = @fwdinghistory.select { |f| f.channel_in == @channel }

    @calculations[:forwarding_count_out]    = forwarding_out.count
    @calculations[:forwarding_count_in]     = forwarding_in.count
    @calculations[:forwarding_volume_out]   = (forwarding_out.sum(&:amount_out_msat) / 1000.0).to_i
    @calculations[:forwarding_volume_in]    = (forwarding_in.sum(&:amount_in_msat) / 1000.0).to_i

    @calculations[:fees_collected_out]      = forwarding_out.sum(&:fee_msat) / 1000.0
    @calculations[:fees_collected_in]       = forwarding_in.sum(&:fee_msat) / 1000.0

    @calculations[:outbound_histogram]      = forwarding_out.group_by { |f| FeeTier.for(f) }
    @calculations[:inbound_histogram]       = forwarding_in.group_by { |f| FeeTier.for(f) }
  end

  class FeeTier
    @tiers = {}

    attr_reader :range

    def initialize(range)
      @range = range
    end

    def lower
      range.first
    end

    def upper
      range.size == Float::INFINITY ? nil : range.last
    end

    def self.tier(ppm_lower, ppm_upper)
      @tiers[[ppm_lower, ppm_upper]] ||= self.new(ppm_lower...ppm_upper)
    end

    def self.for(forwarding)
      case forwarding.effective_fee_ppm.to_i
      when 0...2
        tier(0, 2)
      when 2...5
        tier(2, 5)
      when 6...10
        tier(6, 10)
      when 10...15
        tier(10, 15)
      when 15...20
        tier(15, 20)
      when 20...25
        tier(20, 25)
      when 25...30
        tier(25, 30)
      when 30...40
        tier(30, 40)
      when 40...50
        tier(40, 50)
      when 50...60
        tier(50, 60)
      when 60...80
        tier(60, 80)
      when 80...100
        tier(80, 100)
      when 100...150
        tier(100, 150)
      when 150...200
        tier(150, 200)
      when 200...300
        tier(200, 300)
      when 300...400
        tier(300, 400)
      when 400...500
        tier(400, 500)
      when 500...750
        tier(500, 750)
      when 750...1000
        tier(750, 1000)
      else
        tier(1000, nil)
      end
    end
  end

  def display
    puts "Fee report for channel #{@channel.id.blue.bold} (node #{(@channel.node.alias || @channel.node.pubkey).magenta.italic})"
    puts "#{@start_time.to_s.italic} to #{@end_time.to_s.italic}"
    puts
    puts "Capacity:           #{@channel.capacity.to_s.brown.bold} satoshi (balance: #{('%0.2f' % @channel.balance_ratio).blue}, #{@channel.local_balance.to_s.cyan} : #{@channel.remote_balance.to_s.magenta})"
    puts "Monitoring uptime:  #{'%0.2f' % @channel.uptime_days} days"
    puts
    puts "Forwarding count:   #{calculation(:forwarding_count_out).to_s.cyan.italic} (outbound), #{calculation(:forwarding_count_in).to_s.magenta.italic} (inbound)"
    puts "Forwarding volume:  #{calculation(:forwarding_volume_out).to_s.cyan.bold} satoshi (outbound), #{calculation(:forwarding_volume_in).to_s.magenta.bold} satoshi (inbound)"
    puts "Overall volume:     #{@channel.total_satoshis_sent.to_s.cyan} satoshi (outbound, all-time), #{@channel.total_satoshis_received.to_s.magenta} satoshi (inbound, all-time)"
    puts_hline(char = '=')
    puts "Fees collected:     #{('%0.3f' % calculation(:fees_collected_out)).to_s.cyan.bold} satoshi (outbound, on this channel)"
    puts "#{'Fee (ppm)'.ljust(11)} #{'Outbound fowarding'.ljust(25)} #{'Corresponding inbound sources'}".italic
    puts_hline
    puts_histogram_mode(mode: :outbound)
    puts_hline(char = '=')
    puts "Fees collected:     #{('%0.3f' % calculation(:fees_collected_in)).to_s.magenta.bold} satoshi (inbound, to other channels)"
    puts "#{'Fee (ppm)'.ljust(11)} #{'Inbound fowarding'.ljust(25)} #{'Corresponding outbound destinations'}".italic
    puts_hline
    puts_histogram_mode(mode: :inbound)
  end

  def puts_hline(char = '_')
    puts char * 80
  end

  def puts_gauge(ratio, color:)
    "[#{('|' * (20 * ratio).to_i).ljust(20).send(color)}]"
  end

  def puts_histogram_outbound
    gauge_max = calculation(:outbound_histogram).values.map { |cohort| cohort.sum(&:amount_out_msat) }.max

    calculation(:outbound_histogram).sort_by { |tier, _| tier.range.first }.each do |tier, forwards|
      puts_histogram_row(tier: tier, forwards: forwards, gauge_max: gauge_max, mode: :outbound)
    end
  end

  def puts_histogram_inbound
    gauge_max = calculation(:inbound_histogram).values.map { |cohort| cohort.sum(&:amount_in_msat) }.max

    calculation(:inbound_histogram).sort_by { |tier, _| tier.range.first }.each do |tier, forwards|
      puts_histogram_row(tier: tier, forwards: forwards, gauge_max: gauge_max, mode: :inbound)
    end
  end

  def puts_histogram_row(tier:, forwards:, gauge_max:, corresponding_nodes: 5, mode:)
    lower_ppm = tier.lower
    upper_ppm = tier.upper

    case mode
    when :outbound
      gauge = puts_gauge(forwards.sum(&:amount_out_msat).to_f / gauge_max, color: :cyan)
      arrow = '<-'

      top_corresponding_nodes = forwards.group_by { |f| f.channel_in&.node }
      top_corresponding_nodes = top_corresponding_nodes.map do |node, cohort|
        [node, (cohort.sum(&:amount_in_msat) / 1000.0)]
      end
      top_corresponding_nodes.sort_by! { |_, amount| -amount }
      top_corresponding_nodes.map! { |node, amount| [node, amount / calculation(:forwarding_volume_out)] }
    when :inbound
      gauge = puts_gauge(forwards.sum(&:amount_in_msat).to_f / gauge_max, color: :magenta)
      arrow = '->'

      top_corresponding_nodes = forwards.group_by { |f| f.channel_out&.node }
      top_corresponding_nodes = top_corresponding_nodes.map do |node, cohort|
        [node, (cohort.sum(&:amount_out_msat) / 1000.0)]
      end
      top_corresponding_nodes.sort_by! { |_, amount| -amount }
      top_corresponding_nodes.map! { |node, amount| [node, amount / calculation(:forwarding_volume_in)] }
    else
      raise ArgumentError
    end

    corresponding_nodes = top_corresponding_nodes[0...@show_corresponding_nodes]
    corresponding_nodes = corresponding_nodes.map { |node, ratio| "#{node&.alias || node&.pubkey || '(unknown node)'} (#{'%0.2f' % (ratio * 100)}%)" }.join(', ') + ' ...'

    puts "#{'%4d' % lower_ppm} - #{(upper_ppm.nil? ? '...'.rjust(4) : ('%4d' % upper_ppm))} #{gauge} #{arrow} #{corresponding_nodes.italic}"
  end

  def puts_histogram_mode(mode:)
    case mode
    when :outbound
      puts_histogram_outbound
    when :inbound
      puts_histogram_inbound
    else
      raise ArgumentError
    end
  end
end
