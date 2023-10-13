class Usda_rd < ActiveRecord::Base
  self.table_name = 'usda_rural_development'
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :press_releases])
end

