# frozen_string_literal: true

class HrUmAnnualSalaryRateRun < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :state_salaries__raw])
  self.table_name = 'hr_um_annual_salary_rate_runs'
  self.inheritance_column = :_type_disabled
end
 