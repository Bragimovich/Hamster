class NjEssexCharges < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'nj_essex_charges'
  self.inheritance_column = :_type_disabled
end
