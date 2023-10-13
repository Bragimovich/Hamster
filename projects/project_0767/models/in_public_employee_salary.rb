# frozen_string_literal: true

class InPublicEmployeeSalary < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :state_salaries__raw])
  self.table_name = 'in_public_employee_salaries'
  self.inheritance_column = :_type_disabled
end
