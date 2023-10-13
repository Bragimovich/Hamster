class RiHigherEdSalariesRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :state_salaries__raw])
  self.table_name = 'ri_higher_ed_salaries_runs'
  self.inheritance_column = :_type_disabled
end
