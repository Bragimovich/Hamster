# frozen_string_literal: true

require_relative '../models/pl_gis__cities_lat_lon'
require_relative '../models/us_cities_lat_lon'
require_relative '../models/us_cities_table'
require_relative '../models/us_weather_code'
require_relative '../models/us_weather_forecast_daily'
require_relative '../models/us_weather_forecast_hourly'
require_relative '../models/us_weather_historical_daily'
require_relative '../models/us_weather_historical_hourly'

class  Keeper < Hamster::Harvester
  attr_writer :json

  def get_location
    safe_operation(UsCitiesLatLon) { |model| model.select(:pl_gis_lat, :lp_gis_lon).pluck(:pl_gis_lat, :lp_gis_lon, :time_zone, :id) }
  end

  def store_weather_forecast
    daily = @json["daily"]
    hourly = @json["hourly"]
    daily_arr = []
    hourly_arr = []

    hourly["time"].size.times do |i|
      hourly_hash = {
      time: hourly["time"][i],
      as_of_date: Time.now.strftime("%Y-%m-%d"),
      city_id: @json[:loc_id],
      temperature_2m: hourly["temperature_2m"][i],
      relativehumidity_2m: hourly["relativehumidity_2m"][i],
      apparent_temperature: hourly["apparent_temperature"][i],
      precipitation: hourly["precipitation"][i],
      rain: hourly["rain"][i],
      showers: hourly["showers"][i],
      snowfall: hourly["snowfall"][i],
      snow_depth: hourly["snow_depth"][i],
      freezinglevel_height: hourly["freezinglevel_height"][i],
      weathercode_id: hourly["weathercode"][i],
      windspeed_10m: hourly["windspeed_10m"][i],
      data_source_url: 'https://open-meteo.com/en/docs'
      }
      hourly_arr << hourly_hash
    end

    daily["time"].size.times do |i|
      daily_hash = {
        date: daily["time"][i],
        city_id: @json[:loc_id],
        as_of_date: Time.now.strftime("%Y-%m-%d"),
        temperature_2m_max: daily["temperature_2m_max"][i],
        temperature_2m_min: daily["temperature_2m_min"][i],
        apparent_temperature_max: daily["apparent_temperature_max"][i],
        apparent_temperature_min: daily["apparent_temperature_min"][i],
        precipitation_sum: daily["precipitation_sum"][i],
        rain_sum: daily["rain_sum"][i],
        showers_sum: daily["showers_sum"][i],
        snowfall_sum: daily["snowfall_sum"][i],
        windspeed_10m_max: daily["windspeed_10m_max"][i],
        windgusts_10m_max: daily["windgusts_10m_max"][i],
        sunrise: daily["sunrise"][i],
        sunset: daily["sunset"][i],
        weathercode_id: daily["weathercode"][i],
        data_source_url: 'https://open-meteo.com/en/docs'
      }
      daily_arr << daily_hash
    end
    safe_operation(UsWeatherForecastHourly) { |model| model.insert_all(hourly_arr) }
    safe_operation(UsWeatherForecastDaily) { |model| model.insert_all(daily_arr) }
    #UsWeatherForecastHourly.insert_all(hourly_arr)
    #UsWeatherForecastDaily.insert_all(daily_arr)
  end

  def store_weather_historical
    daily = @json["daily"]
    hourly = @json["hourly"]
    daily_arr = []
    hourly_arr = []

    hourly["time"].size.times do |i|
      hourly_hash = {
      time: hourly["time"][i],
      city_id: @json[:loc_id],
      temperature_2m: hourly["temperature_2m"][i],
      relativehumidity_2m: hourly["relativehumidity_2m"][i],
      apparent_temperature: hourly["apparent_temperature"][i],
      precipitation: hourly["precipitation"][i],
      rain: hourly["rain"][i],
      snowfall: hourly["snowfall"][i],
      cloudcover: hourly["cloudcover"][i],
      data_source_url: 'https://open-meteo.com/en/docs/historical-weather-api'
      }
      hourly_arr << hourly_hash
    end

    daily["time"].size.times do |i|
      daily_hash = {
        date: daily["time"][i],
        city_id: @json[:loc_id],
        temperature_2m_max: daily["temperature_2m_max"][i],
        temperature_2m_min: daily["temperature_2m_min"][i],
        precipitation_sum: daily["precipitation_sum"][i],
        rain_sum: daily["rain_sum"][i],
        snowfall_sum: daily["snowfall_sum"][i],
        windspeed_10m_max: daily["windspeed_10m_max"][i],
        windgusts_10m_max: daily["windgusts_10m_max"][i],
        sunrise: daily["sunrise"][i],
        sunset: daily["sunset"][i],
        data_source_url: 'https://open-meteo.com/en/docs/historical-weather-api'
      }
      daily_arr << daily_hash
    end
    safe_operation(UsWeatherHistoricalHourly) { |model| model.insert_all(hourly_arr) }
    safe_operation(UsWeatherHistoricalDaily) { |model| model.insert_all(daily_arr) }
    #UsWeatherHistoricalHourly.insert_all(hourly_arr)
    #UsWeatherHistoricalDaily.insert_all(daily_arr)
  end

  def safe_operation(model, retries=0) 
    begin
      yield(model)
    rescue *connection_error_classes => e
      pp e.full_message
      puts retries += 1
      puts '*'*77, "Reconnect!", '*'*77
      sleep retries*2
      model.connection.close rescue nil
      retry if retries < 15
    end
  end

  def connection_error_classes
    [
      ActiveRecord::ConnectionNotEstablished,
      Mysql2::Error::ConnectionError,
      ActiveRecord::StatementInvalid,
      ActiveRecord::LockWaitTimeout
    ]
  end
end
