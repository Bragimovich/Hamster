class MiWayneChargesAndBonds < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'mi_wayne_charges_and_bonds'
  self.inheritance_column = :_type_disabled
end