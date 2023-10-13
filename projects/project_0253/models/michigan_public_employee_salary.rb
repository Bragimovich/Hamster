# frozen_string_literal: true

class MichiganPublicEmployeeSalary< ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'michigan_public_employee_salary'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
