# frozen_string_literal: true

class AlCcEmployeeSalariesRun < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :state_salaries__raw])
  self.table_name = 'al_cc_employee_salaries_runs'
  self.inheritance_column = :_type_disabled
end
