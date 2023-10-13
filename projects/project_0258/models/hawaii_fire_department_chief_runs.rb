# frozen_string_literal: true

class HawaiiFireDepartmentChiefRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
   
  self.table_name = 'hawaii_fire_department_chief_runs'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
