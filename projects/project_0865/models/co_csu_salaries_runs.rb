class CoCsuSalariesRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :state_salaries__raw])
  self.table_name = 'co_csu_salaries_runs'
  self.inheritance_column = :_type_disabled
end
