class MaDhcdRun < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :press_releases])
  self.table_name = 'ma_dhcd_run'
  self.inheritance_column = :_type_disabled
end
