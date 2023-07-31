class ScryingOrb::MatrixCorrelationReport
  def initialize(start_time:, end_time:, channel_list:, show_nodes: 30)
    @start_time = start_time
    @end_time   = end_time

    @channel_list = channel_list

    @fwdinghistory = ScryingOrb::ForwardingHistory.new(start_time: start_time, end_time: end_time, channel_list: channel_list).history

    @show_nodes = show_nodes

    calculate
  end

  def calculation(key)
    @calculations.fetch(key)
  end

  def calculate
    @calculations = {}

    volume_forwarded = {}
    all_node_in = @fwdinghistory.group_by { |f| f.channel_in&.node }.map { |node, cohort| [node, cohort.sum(&:amount_in_msat)] }.sort_by { |_, amount| -amount }
    all_node_out = @fwdinghistory.group_by { |f| f.channel_out&.node }.map { |node, cohort| [node, cohort.sum(&:amount_out_msat)] }.sort_by { |_, amount| -amount}

    top_nodes_in = [*all_node_in[0...@show_nodes].map(&:first), nil]
    top_nodes_out = [*all_node_in[0...@show_nodes].map(&:first), nil]

    top_nodes_in.each do |node_in|
      volume_forwarded[node_in] = {}

      top_nodes_out.each do |node_out|
        volume_forwarded[node_in][node_out] = 0
      end
    end

    @fwdinghistory.each do |f|
      outputs =
        if volume_forwarded.key?(f.channel_in&.node)
          volume_forwarded[f.channel_in&.node]
        else
          volume_forwarded[nil]
        end

      if outputs.key?(f.channel_out&.node)
        outputs[f.channel_out&.node] += f.amount_out_msat / 1000.0
      else
        outputs[nil] += f.amount_out_msat / 1000.0
      end
    end

    @calculations[:volume_forwarded] = volume_forwarded
    @calculations[:max_value] = volume_forwarded.values.map(&:values).flatten.max
    @calculations[:top_nodes_in] = top_nodes_in
    @calculations[:top_nodes_out] = top_nodes_out
  end

  def display
    puts "Correlation report (top #{@show_nodes} nodes)"
    puts "#{@start_time.to_s.italic} to #{@end_time.to_s.italic}"
    puts
    puts_color_scale
    puts
    puts_matrix
  end

  def puts_matrix
    volume = calculation(:volume_forwarded)

    calculation(:top_nodes_in).each do |node_in|
      calculation(:top_nodes_out).each do |node_out|
        color = color_grade(volume[node_in][node_out])
        print '. '.send(color).gray
      end

      puts " <- #{node_in&.alias || node_in&.pubkey || '(other)'}"
    end

    longest_name = calculation(:top_nodes_out).max { |node| node&.alias&.length || node&.pubkey&.length || 7 }
    num_nodes_out = calculation(:top_nodes_out).count

    num_nodes_out.times { print '| ' }; puts
    calculation(:top_nodes_out).reverse.each_with_index do |node, n|
      (num_nodes_out - n - 1).times { print '| ' }
      print '`-> '
      puts node&.alias || node&.pubkey || '(other)'
    end
  end

  def puts_color_scale
    n = @calculations[:max_value]

    print ' 0.0% -  12.5%'.bg_black
    puts " ~ #{(n * 0.125).to_i} satoshi".rjust(30)
    print '12.5% -  25.0%'.bg_red
    puts " ~ #{(n * 0.25).to_i} satoshi".rjust(30)
    print '25.0% -  3.75%'.bg_brown
    puts " ~ #{(n * 0.375).to_i} satoshi".rjust(30)
    print '37.5% -  50.0%'.bg_green
    puts " ~ #{(n * 0.5).to_i} satoshi".rjust(30)
    print '50.0% -  62.5%'.bg_cyan
    puts " ~ #{(n * 0.625).to_i} satoshi".rjust(30)
    print '62.5% -  75.0%'.bg_blue
    puts " ~ #{(n * 0.75).to_i} satoshi".rjust(30)
    print '75.0% -  87.5%'.bg_magenta
    puts " ~ #{(n * 0.875).to_i} satoshi".rjust(30)
    print '87.5% - 100.0%'.bg_gray
    puts " ~ #{n.to_i} satoshi".rjust(30)
  end

  def color_grade(amount)
    case (amount.to_f / @calculations[:max_value])
    when ...0.125
      :bg_black
    when 0.125...0.25
      :bg_red
    when 0.25...0.375
      :bg_brown
    when 0.375...0.5
      :bg_green
    when 0.5...0.625
      :bg_cyan
    when 0.625...0.75
      :bg_blue
    when 0.75...875
      :bg_magenta
    when 0.875..
      :bg_gray
    else
      raise ArgumentError
    end
  end
end
