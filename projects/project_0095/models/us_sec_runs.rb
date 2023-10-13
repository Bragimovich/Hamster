class USSECRuns < ActiveRecord::Base
  self.table_name = 'us_sec_runs'
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :press_releases])
end
