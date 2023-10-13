# frozen_string_literal: true

class FlPublicEmployeeSalariesRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'fl_public_employee_salaries_runs'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
