class IowaCities < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :hle_resources])
  self.table_name = 'zipcode_data'
  self.inheritance_column = :_type_disabled
end
