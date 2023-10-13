# frozen_string_literal: true

require_relative '../lib/gasbuddy_scraper'
require_relative '../lib/gasbuddy_keeper'
require_relative '../lib/gasbuddy_parser'

require_relative '../models/us_zips'
require_relative '../models/gasbuddy_zip_searched'
require_relative '../models/gasbuddy_gas_stations'
require_relative '../models/gasbuddy_gas_prices'
require_relative '../models/gasbuddy_gas_trends'
require_relative '../models/gasbuddy_gas_stations_runs'

class GasBuddyManager < Hamster::Harvester

  QUANT = 10

  def initialize
    super
    @keeper = GasBuddyKeeper.new
    @scraper = GasBuddyScraper.new
    @parser = GasBuddyParser.new
  end

  def start
    finished = @keeper.finished?
    if finished
      send_to_slack("Project #180 started")
      @keeper.start
      # zips = @keeper.list_all_zips(USZip).select.with_index{|_,i| i % 20 == 0}
      # zips = @keeper.list_all_zips(USZip).first(QUANT)
      zips = @keeper.list_all_zips(USZip)
      zip_md5 = Set.new
      saved_stations = Set.new
    else
      send_to_slack("Project #180 restarted from last zip")
      @keeper.restart
      last_zip = @keeper.last_zip_recorded(GasBuddyZip) || '';
      # zips = @keeper.list_all_zips(USZip).select.with_index{|_,i| i % 20 == 0}.select { |e| e >= last_zip }
      # zips = @keeper.list_all_zips(USZip).first(QUANT).select { |e| e >= last_zip }
      zips = @keeper.list_all_zips(USZip).select { |e| e >= last_zip }
      zip_md5 = @keeper.collect_prestored_zip_md5(GasBuddyZip)
      saved_stations = @keeper.collect_prestored_station_id(GasBuddyStations)
    end
    # GasBuddyZip collects all working ZIPs and controls their duplicates

    store(zips, zip_md5, saved_stations)

    @keeper.finish
    send_to_slack("Project #180 finished")
  rescue => e
    print_all e.inspect, e.full_message, title: " ERROR "
    send_to_slack("Project #180 start:\n#{e.inspect}")
  end

  def store(zips, zip_md5, presaved_ids)
    zips.each do |z|
      p "#{"="*50} #{z} #{"="*50}"
      stations, trends, new_md5 = zip_data(z, zip_md5)
      next unless [stations, trends, new_md5].all?
      next if @parser.no_stations(stations)
      next if @parser.country_not_us(stations)

      store_zip_md5(z, new_md5, zip_md5)
      store_stations(z, stations, presaved_ids)
      store_trends(z, stations, trends)
    rescue StandardError => e
      print_all e.inspect, e.full_message, title: " ERROR "
      send_to_slack("Project #180 store (zip: #{z}):\n#{e.inspect}")
    end
    update_deleted_status
  end

  def zip_data(zip, z_md5)

    parsed = zip_data_fragment(zip, 0.to_s)
    return if parsed.nil?

    stations, trends = parsed["stations"], parsed["trends"]
    count = stations['count']

    new_zip_md5 = @parser.calc_zip_md5(parsed, count, @keeper.run_id)
    return if z_md5.include?( new_zip_md5 )

    return [stations, trends, new_zip_md5] if count <= 10

    iterations = number_of_iterations(count) - 1
    iterations.times do |n|
      begin
        parsed = zip_data_fragment(zip, ((n + 1) * 10).to_s)
        parsed = zip_data_fragment(zip, ((n + 1) * 10).to_s, "") if parsed.nil?
        stations['results'].concat(parsed['stations']['results']) unless parsed.nil?
      end
    end
    [stations, trends, new_zip_md5]
  rescue StandardError => e
    print_all e.inspect, e.full_message, title: " ERROR "
    send_to_slack("Project #180 zip_data (zip: #{zip}):\n#{e.inspect}")
    nil
  end

  def zip_data_fragment(zip, cursor, timezone = "timezone")
    try ||= 1
    response = @scraper.data_by_api(zip, cursor, timezone)
    @parser.parse_response(response)
  rescue StandardError => e
    if try < 3
      try += 1
      sleep 2 ** try
      retry
    end
    print_all e.inspect, e.full_message, title: " ERROR "
    send_to_slack("Project #180 zip_data_fragment (zip: #{zip}, cursor: #{cursor}):\n#{e.inspect}")
    nil
  end

  def number_of_iterations(count)
    (count / 10.to_f).ceil
  end

  def store_zip_md5(z, new_md5, zip_md5)
    zip_md5.add(new_md5)
    @keeper.update_zip_data(z, new_md5, GasBuddyZip)
  end

  def store_stations(zip, stations, presaved_ids)
    zip_stations = []
    zip_prices = []
    unchanged_zip_stations = []
    unchanged_zip_prices = []
    stored_stations = @keeper.list_stations_md5_by_zip(zip, GasBuddyStations)
    stored_prices = @keeper.list_prices_md5_by_zip(zip, GasBuddyPrices)
    stations['results'].each do |s|
      next if presaved_ids.include?( s['id'].to_i )
      presaved_ids.add( s['id'].to_i )
      zip_station = @parser.parse_station(zip, s)
      if stored_stations.include? zip_station[:md5_hash]
        unchanged_zip_stations.push zip_station[:md5_hash]
      else
        zip_stations.push zip_station
      end
      station_prices, unchanged_prices_md5 = parse_station_prices(zip, s, stored_prices)
      zip_prices.concat(station_prices)
      unchanged_zip_prices.concat(unchanged_prices_md5)
    end

    @keeper.update_all_touched_run_id(GasBuddyStations, unchanged_zip_stations)
    @keeper.update_all_touched_run_id(GasBuddyPrices, unchanged_zip_prices)

    @keeper.store_all(zip_stations, GasBuddyStations)
    @keeper.store_all(zip_prices, GasBuddyPrices)
  rescue StandardError => e
    print_all e.inspect, e.full_message, title: " ERROR "
    send_to_slack("Project # 0180 store_stations (zip: #{zip})\n#{e.inspect}")
  end

  def parse_station_prices(zip, station, stored_prices)
    station_prices = []
    unchanged_prices = []
    station['prices'].each do |price|
      next if price.empty?
      station_price = @parser.parse_price(zip, station, price)
      next if @parser.no_credit_price(station_price) && @parser.no_cash_price(station_price)
      if stored_prices.include? station_price[:md5_hash]
        unchanged_prices.push station_price[:md5_hash]
      else
        station_prices.push station_price
      end
    end
    [station_prices, unchanged_prices]
  rescue StandardError => e
    print_all e.inspect, e.full_message, title: " ERROR "
    send_to_slack("Project #180 parse_station_prices (zip: #{zip}):\n#{e.inspect}")
    []
  end

  def store_trends(zip, stations, zip_trends)
    station_count = @parser.count(stations)
    trends = @parser.parse_trends(zip, station_count, zip_trends)
    if @keeper.update_touched_run_id(GasBuddyTrends, trends[:md5_hash]) == 0
      @keeper.store(trends, GasBuddyTrends)
    end
  rescue StandardError => e
    print_all e.inspect, e.full_message, title: " ERROR "
    send_to_slack("Project #180 store_trends (zip: #{zip}):\n#{e.inspect}")
  end

  def update_deleted_status
    @keeper.update_deleted_status(GasBuddyStations)
    @keeper.update_deleted_status(GasBuddyPrices)
    @keeper.update_deleted_status(GasBuddyTrends)
  end

  def print_all(*args, title: nil, line_feed: true)
    puts "#{"=" * 50}#{title}#{"=" * 50}" if title
    puts args
    puts if line_feed
  end

  def send_to_slack(message)
    Hamster.report(to: 'U031HSK8TGF', message: message)
  end

end
