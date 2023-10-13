# frozen_string_literal: true

class HFDCMonthlyReports < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
   
  self.table_name = 'hawaii_fire_department_chief_monthly_report'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
