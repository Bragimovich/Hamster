class CeiData < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'cei_data'
  self.inheritance_column = :_type_disabled
end
