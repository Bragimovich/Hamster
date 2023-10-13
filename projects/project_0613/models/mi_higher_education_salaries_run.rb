class MIHigherEducationSalariesRuns < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'mi_higher_education_salaries_run'
end
