class AzAaac2CaseRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'az_aac2_case_runs'
  self.inheritance_column = :_type_disabled
end
