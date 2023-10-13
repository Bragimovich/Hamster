# frozen_string_literal: true

class UsCitiesLatLon < ActiveRecord::Base
    self.inheritance_column = :_type_disabled
    establish_connection(Storage[host: :db01, db: :usa_raw])
    include Hamster::Granary
  
    self.table_name = 'us_cities_lat_lon'
    self.logger = Logger.new(STDOUT)
end
