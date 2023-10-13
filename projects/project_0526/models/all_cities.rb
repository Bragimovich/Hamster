class AllCities < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :hle_resources])
  self.table_name = 'usa_administrative_division_places'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end