# frozen_string_literal: true
class VtEmployeeSalariesRun < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :state_salaries__raw])
  self.table_name = 'vt_employee_salaries_run'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
