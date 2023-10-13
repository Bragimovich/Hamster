class MaDhcd < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :press_releases])
  self.table_name = 'ma_dhcd'
  self.inheritance_column = :_type_disabled
end
