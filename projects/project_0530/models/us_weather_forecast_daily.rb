# frozen_string_literal: true

class UsWeatherForecastDaily < ActiveRecord::Base
    self.inheritance_column = :_type_disabled
    establish_connection(Storage[host: :db01, db: :usa_raw])
    include Hamster::Granary
  
    self.table_name = 'us_weather_forecast_daily'
    self.logger = Logger.new(STDOUT)
end
