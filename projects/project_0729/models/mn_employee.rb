# frozen_string_literal: true
class EmployeePayroll < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :state_salaries__raw])
  self.table_name = 'mn_employee_payroll_data'
  self.inheritance_column = :_type_disabled
end
