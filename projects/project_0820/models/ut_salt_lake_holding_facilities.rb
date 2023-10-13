class UtSaltLakeHoldingFacilities < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'ut_salt_lake_holding_facilities'
  self.inheritance_column = :_type_disabled
end
