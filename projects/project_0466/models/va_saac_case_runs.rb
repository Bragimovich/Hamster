class VaSaacCaseRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'va_saac_case_runs'
  self.inheritance_column = :_type_disabled
end
