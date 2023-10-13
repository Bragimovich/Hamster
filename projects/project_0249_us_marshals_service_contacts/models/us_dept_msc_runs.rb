class UsDeptMscRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :press_releases])
  self.table_name = 'us_dept_msc_runs'
  self.inheritance_column = :_type_disabled
end
