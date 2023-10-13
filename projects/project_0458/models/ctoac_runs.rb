class CTOACRuns < ActiveRecord::Base
  self.table_name = 'us_dept_ctoac__runs'
  establish_connection(Storage[host: :db02, db: :press_releases])
end

