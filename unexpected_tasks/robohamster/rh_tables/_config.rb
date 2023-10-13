class RH_Configs < ActiveRecord::Base
  self.table_name = '_configs'
  establish_connection(Storage[host: :db02, db: :robohamster])
end
