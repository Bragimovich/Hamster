class IlLcCaseRuns < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :us_court_cases])

  self.table_name = 'il_lc_case_runs'
  self.logger = Logger.new(STDOUT)
end
