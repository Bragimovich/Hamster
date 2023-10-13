class WestchesterNewYorkInmates < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'westchester_new_york_inmates'
  self.inheritance_column = :_type_disabled
end
