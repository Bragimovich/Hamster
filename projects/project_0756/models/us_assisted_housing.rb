class UsAssistedHousing < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'us_assisted_housing'
  self.inheritance_column = :_type_disabled
end
