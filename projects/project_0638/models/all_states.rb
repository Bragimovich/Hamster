class AllStates < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :hle_resources])
  self.table_name = 'usa_administrative_division_states'
  self.inheritance_column = :_type_disabled
end