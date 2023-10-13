class UtSaltLakeCharges < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'ut_salt_lake_charges'
  self.inheritance_column = :_type_disabled
end
