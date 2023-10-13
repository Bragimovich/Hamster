class NjEssexArrests < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'nj_essex_arrests'
  self.inheritance_column = :_type_disabled
end
