# frozen_string_literal: true
class EmployeeSalaries < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :state_salaries__raw])
  self.table_name = 'mn_public_employee_salaries'
  self.inheritance_column = :_type_disabled
end
