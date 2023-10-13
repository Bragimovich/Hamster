# frozen_string_literal: true

class NewYorkCityCrimeStatisticsYearlyHistory < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  include Hamster::Granary
  
  self.table_name = 'new_york_city_crime_statistics_yearly_history'
end
