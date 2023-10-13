# frozen_string_literal: true

class PhiladelphiaCrimeStatsYearToDate < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  include Hamster::Granary
  
  self.table_name = 'philadelphia_crime_stats_year_to_date'
  self.logger = Logger.new(STDOUT)
end   
