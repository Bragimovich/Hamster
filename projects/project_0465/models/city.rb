class City < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :hle_resources])

  self.table_name = 'usa_administrative_division_counties_places_matching'
  self.logger = Logger.new(STDOUT)
end
