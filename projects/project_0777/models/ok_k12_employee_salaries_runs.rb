class OkK12EmployeeSalariesRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :state_salaries__raw])
  self.table_name = 'ok_k12_employee_salaries_runs'
  self.inheritance_column = :_type_disabled
end
