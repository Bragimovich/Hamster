class UsDeptMsc < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :press_releases])
  self.table_name = 'us_dept_msc'
  self.inheritance_column = :_type_disabled
end
