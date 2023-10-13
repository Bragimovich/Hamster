# frozen_string_literal: true

class DcPublicEmployeeSalariesRun < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :state_salaries__raw])
  self.table_name = 'dc_public_employee_salaries_runs'
  self.inheritance_column = :_type_disabled
end
