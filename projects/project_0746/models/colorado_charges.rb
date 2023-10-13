class ColoradoCharges < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'colorado_charges'
  self.inheritance_column = :_type_disabled
end
