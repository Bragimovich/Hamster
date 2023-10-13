class ArizonaCitiesAndZips < ActiveRecord::Base
  self.table_name = 'zipcode_data'
  establish_connection(Storage[host: :db02, db: :hle_resources])
end
