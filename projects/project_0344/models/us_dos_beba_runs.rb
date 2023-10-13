class UsDosBebaRuns < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  include Hamster::Loggable

  establish_connection(Storage[host: :db02, db: :press_releases])
  self.table_name = 'us_dos_beba_runs'
end
