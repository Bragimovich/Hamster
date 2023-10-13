class CTOAC < ActiveRecord::Base
  self.table_name = 'us_dept_ctoac'
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :press_releases])
end

