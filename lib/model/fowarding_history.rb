require 'etc'
require 'json'

class ScryingOrb::ForwardingHistory
  SHARED_MEMORY_CACHE_DIR = '/dev/shm'

  def initialize(start_time:, end_time:, channel_list:)
    initialize_cache

    @start_time = start_time
    @end_time   = end_time
    @time_range = TripartiteTimeRange.new(start_time: start_time, end_time: end_time)

    ScryingOrb.log.info { "loading forwarding history (#{@time_range.inspect})" }

    @fwdinghistory = load_history(channel_list: channel_list)

    ScryingOrb.log.info { "forwarding history count: #{@fwdinghistory.count}" }
  end

  def initialize_cache
    uid = Etc.getpwuid.uid

    if !File.exist?(cache_dir)
      Dir.mkdir(cache_dir)
      File.chmod(0700, cache_dir)
    else
      raise "#{cache_dir} is not a directory" unless File.directory?(cache_dir)
      raise "#{cache_dir} is not owned by user #{uid}" unless File.stat(cache_dir).uid == uid
      raise "#{cache_dir} does not have permissions set to mode 0700" unless File.stat(cache_dir).mode & 07777 == 0700
    end
  end

  def cache_dir(append_path = nil)
    uid = Etc.getpwuid.uid

    path = File.join(SHARED_MEMORY_CACHE_DIR, ".scrying-orb-#{uid.to_s}")
    append_path.nil? ? path : File.join(path, append_path)
  end

  def cache_file_fwdinghistory(date)
    cache_dir("fwdinghistory_#{date.year}-#{'%02d' % date.month}-#{'%02d' % date.day}.json")
  end

  def history
    @fwdinghistory
  end

  def load_history(channel_list:)
    combined_history = []

    start_time, end_time = @time_range.start_partial_day
    combined_history.concat(get_forwarding_history(start_time: start_time, end_time: end_time))

    @time_range.whole_day_intervals do |start_time, end_time|
      cache_file = cache_file_fwdinghistory(start_time)

      if File.exist?(cache_file)
        combined_history.concat(JSON.load(File.read(cache_file)))
      else
        history = get_forwarding_history(start_time: start_time, end_time: end_time)

        File.write(cache_file, '')
        File.chmod(0600, cache_file)
        File.write(cache_file, JSON.dump(history))

        combined_history.concat(history)
      end
    end

    unless @time_range.end_partial_day.nil?
      start_time, end_time = @time_range.end_partial_day
      combined_history.concat(get_forwarding_history(start_time: start_time, end_time: end_time))
    end

    combined_history.map { |f| Forwarding.new(details: f, channel_list: channel_list) }
  end

  def get_forwarding_history(start_time:, end_time:, pagination_size: 1000)
    result = []
    pagination_offset = 0

    loop do
      output = ScryingOrb::Calls.lncli_fwdinghistory(
        start_time: start_time,
        end_time: end_time,
        index_offset: pagination_offset,
        max_events: pagination_size
      )

      events      = output.fetch('forwarding_events')
      last_offset = output.fetch('last_offset_index')

      result.concat(events)

      break if last_offset < (pagination_offset + pagination_size)

      pagination_offset += pagination_size
    end

    result
  end
end

class Forwarding
  attr_reader *%i[
    timestamp
    channel_in
    channel_out
    amount_in_msat
    amount_out_msat
    fee_msat
  ]

  def initialize(details:, channel_list:)
    @timestamp        = Time.at(details.fetch('timestamp').to_i)

    @channel_in       = channel_list.channel(details.fetch('chan_id_in'))
    @channel_out      = channel_list.channel(details.fetch('chan_id_out'))

    @amount_in_msat   = details.fetch('amt_in_msat').to_i
    @amount_out_msat  = details.fetch('amt_out_msat').to_i

    @fee_msat         = details.fetch('fee_msat').to_i
  end

  def effective_fee_ppm
    fee_msat * 1000000.0 / amount_out_msat
  end
end

class TripartiteTimeRange
  def initialize(start_time:, end_time:)
    raise 'start time comes after end time' if start_time > end_time

    start_whole_day = day_truncate(add_day(start_time))
    end_whole_day   = day_truncate(end_time)

    date_diff = end_whole_day - start_whole_day

    if date_diff < 0
      ScryingOrb.log.info { "one partial day: #{(end_time - start_time) / 3600} hours" }

      @start_partial_day = [start_time, end_time]
      @end_partial_day = nil

      @day_intervals = nil

    elsif date_diff == 0
      ScryingOrb.log.info { "one partial day split over two days: #{(end_time - start_time) / 3600} hours" }

      @start_partial_day = [start_time, start_whole_day]
      @end_partial_day = [end_whole_day, end_time]

      @day_intervals = nil
    else
      ScryingOrb.log.info { "whole days: #{(date_diff / 86400).to_i}" }

      @start_partial_day = [start_time, start_whole_day]
      @end_partial_day = [end_whole_day, end_time]

      interval = start_whole_day
      @day_intervals = []

      while (interval < end_whole_day)
        next_interval = interval + 86400
        @day_intervals.append([interval, next_interval])
        interval = next_interval
      end
    end
  end

  def add_day(time)
    time + 86400
  end

  def day_truncate(time)
    Time.new(time.year, time.month, time.day)
  end

  def start_partial_day
    @start_partial_day.map(&:to_i)
  end

  def end_partial_day
    @end_partial_day&.map(&:to_i)
  end

  def whole_day_intervals
    @day_intervals&.each do |day|
      yield [day.first, day.last]
    end
  end

  def whole_days
    @day_intervals&.count || 0
  end

  def inspect
    "<TripartiteTimeRange start partial: #{@start_partial_day.inspect}, end partial: #{@end_partial_day.inspect}, whole days: #{whole_days}>"
  end
end
