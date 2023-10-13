class MiWayneBonds < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'mi_wayne_bonds'
  self.inheritance_column = :_type_disabled
end