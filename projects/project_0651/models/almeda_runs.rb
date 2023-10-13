class AlmedaRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])

  self.table_name = 'ca_acsc_case_runs'
  self.inheritance_column = :_type_disabled
end
