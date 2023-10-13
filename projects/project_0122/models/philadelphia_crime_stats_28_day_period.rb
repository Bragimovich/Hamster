# frozen_string_literal: true

class PhiladelphiaCrimeStats28DayPeriod < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  include Hamster::Granary
  
  self.table_name = 'philadelphia_crime_stats_28_day_period'
  self.logger = Logger.new(STDOUT)
end    
