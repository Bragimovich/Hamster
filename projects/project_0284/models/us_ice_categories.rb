class US_ice_c < ActiveRecord::Base
  self.table_name = 'us_ice_categories'
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :press_releases])
end


