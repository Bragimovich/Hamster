class InmatesRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'ut_utah_inmates_runs'
  self.inheritance_column = :_type_disabled
end
