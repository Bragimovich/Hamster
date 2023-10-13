# frozen_string_literal: true

class PhiladelphiaCrimeStatsReports < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  include Hamster::Granary
  
  self.table_name = 'philadelphia_crime_stats_reports'
  self.logger = Logger.new(STDOUT)
end   
 