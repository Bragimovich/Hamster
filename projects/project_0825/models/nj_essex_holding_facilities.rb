class NjEssexHoldingFacilities < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'nj_essex_holding_facilities'
  self.inheritance_column = :_type_disabled
end
