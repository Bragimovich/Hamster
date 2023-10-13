# frozen_string_literal: true
class GaEmployeeCompensation < ActiveRecord::Base
  establish_connection(Storage[host: :db01 , db: :usa_raw])
  self.table_name = 'ga_employee_compensation'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new($stdout)
end
