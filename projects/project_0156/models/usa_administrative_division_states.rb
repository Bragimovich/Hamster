class USAStates < ActiveRecord::Base
  self.table_name = 'usa_administrative_division_states'
  establish_connection(Storage[host: :db02, db: :hle_resources])
end
