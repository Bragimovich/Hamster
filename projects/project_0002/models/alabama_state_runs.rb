class AlabamaRuns < ActiveRecord::Base
    establish_connection(Storage[host: :db13, db: :usa_raw])
    self.table_name = 'alabama_state_runs'
    self.inheritance_column = :_type_disabled
end
