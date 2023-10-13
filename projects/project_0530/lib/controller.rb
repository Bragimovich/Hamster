# frozen_string_literal: true

require_relative '../models/us_cities_lat_lon'
require_relative '../models/us_weather_forecast_daily'
require_relative '../models/us_weather_forecast_hourly'

class Controller
  def initialize
    time = Time.now.strftime("%Y-%m-%d")
    @city_count = UsCitiesLatLon.select(:id).where.not(time_zone: nil).pluck(:id).count
    @daily_forecast = UsWeatherForecastDaily.select(:id).where(as_of_date: time).pluck(:id).count
    @horly_forecast = UsWeatherForecastHourly.select(:id).where(as_of_date: time).pluck(:id).count

    Hamster.report(to: 'victor lynnyk', message: "Number of records in the table forecast_daily is not as expected: #{@daily_forecast}") if (@city_count *6) != @daily_forecast
    Hamster.report(to: 'victor lynnyk', message: "Number of records in the table horly_forecast is not as expected: #{@horly_forecast}") if (@city_count *6*24) != @horly_forecast
  end
end
