class FdicRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :press_releases])

  self.table_name = 'fdic_runs'
  self.inheritance_column = :_type_disabled
end
