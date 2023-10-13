class US_hca_mi < ActiveRecord::Base
  self.table_name = 'us_dept_hca_minority'
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :press_releases])
end
