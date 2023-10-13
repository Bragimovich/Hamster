class MiWayneCourtHearings < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'mi_wayne_court_hearings'
  self.inheritance_column = :_type_disabled
end