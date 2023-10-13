class VT_hfa < ActiveRecord::Base
  self.table_name = 'vt_housing_finance_agency'
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :press_releases])
end
