class CoDenverRuns < ActiveRecord::Base
    establish_connection(Storage[host: :db01, db: :crime_inmate])
    self.table_name = 'co_denver_inmate_runs'
    self.inheritance_column =:_type_disabled
end