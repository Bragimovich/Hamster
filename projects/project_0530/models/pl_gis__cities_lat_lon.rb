# frozen_string_literal: true

class PlGisCitiesLatLon < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :hle_resources])
  include Hamster::Granary

  self.table_name = 'pl_gis__cities_lat_lon'
  self.logger = Logger.new(STDOUT)
end
