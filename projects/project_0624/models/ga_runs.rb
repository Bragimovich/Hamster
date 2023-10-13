class GaRuns < ActiveRecord::Base
    include Hamster::Loggable
    
    establish_connection(Storage[host: :db01, db: :us_schools_raw])
    self.table_name = 'ga_runs'
    self.inheritance_column = :_type_disabled
end