# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  def initialize(options)
    super
    @keeper = Keeper.new
    @scraper = Scraper.new
    @location = @keeper.get_location

    if options[:single].nil?
      part  = @location.size / options[:instances] + 1
      @location = @location[(options[:instance] * part)...((options[:instance] + 1) * part)]
    end
  end
  
  def download_forecast
    @location.each do |loc|
      retries = 0
      unless loc[0] == nil
        begin
          json = @scraper.link_by_forecast(loc)
        rescue => e
          retries += 1
          sleep 5
          (retries < 5) ? retry :  nil
          Hamster.report to: 'victor lynnyk', message: "530 block json: #{json} :#{e.full_message}"
        end

        unless json.nil?
          json.merge!(loc_id: loc[3])
          @keeper.json = json
          @keeper.store_weather_forecast
        end
      end
    end
  end

  def download_historical
    @location.each do |loc|
      retries = 0
      unless loc[0] == nil
        begin
          json = @scraper.link_by_historical(loc)
        rescue => e
          retries += 1
          sleep 5
          (retries < 5) ? retry : nil
          Hamster.report to: 'victor lynnyk', message: "530 block json: #{json} :#{e.full_message}"
        end

        unless json.nil?
          json.merge!(loc_id: loc[3])
          @keeper.json = json
          @keeper.store_weather_historical
        end
      end
    end
  end

  def load_lat_lon
    city = UsCitiesTable.select(:state, :city_nm).pluck(:state, :city_nm)
    city.each do |val|
      res = PlGisCitiesLatLon.where(state_code: val[0], name: val[1]).pluck(:state_code, :name, :intptlat, :intptlon).flatten
      raw_hash = {state: res[0], city: res[1], pl_gis_lat: res[2], lp_gis_lon: res[3]}
      hash = UsCitiesLatLon.flail { |key| [key, raw_hash[key]] }
      UsCitiesLatLon.update(hash)
    end
  end

  def load_city
    value = UsCitiesLatLon.select(:state, :city, :id).where(pl_gis_lat: nil).pluck(:state, :city, :id)
    value.each do |val|
      res = PlGisCitiesLatLon.where("name like '%#{val[1]}%' and state_code = '#{val[0]}'").pluck(:state_code, :name, :intptlat, :intptlon)
      unless res.empty?
       UsCitiesLatLon.find_by(id: val[2] ).update(pl_gis_lat:res.first[2], lp_gis_lon: res.first[3])
      end
    end
  end

  def load_all_city
    arr = []
    count = 0
    all_city = PlGisCitiesLatLon.select(:state_code, :name, :intptlat, :intptlon).pluck(:state_code, :name, :intptlat, :intptlon)
    all_city.each do |city|
      raw_hash = {state: city[0], city: city[1], pl_gis_lat: city[2], lp_gis_lon: city[3]}
      arr << raw_hash
      count += 1
      if count == 1000 || city == city.last
        UsCitiesLatLon.insert_all(arr)
        arr.clear
        count = 0
      end
    end
  end

  def update_time_zone
    lat_lon = UsCitiesLatLon.select(:pl_gis_lat, :lp_gis_lon, :id).where(time_zone: nil).pluck(:pl_gis_lat, :lp_gis_lon, :id)
    lat_lon.each do |val|
      unless val[0].nil?
      json = @scraper.seach_zone(val)
      UsCitiesLatLon.find_by(id: val[2]).update(time_zone: json["zoneName"])
      end
    end
  end
end
