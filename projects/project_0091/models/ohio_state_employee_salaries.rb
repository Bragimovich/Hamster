# frozen_string_literal: true

class OhioStateEmployeeSalaries < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :usa_raw])
  include Hamster::Granary

  self.table_name = 'ohio_state_employee_salaries'
  self.logger = Logger.new(STDOUT)
end
