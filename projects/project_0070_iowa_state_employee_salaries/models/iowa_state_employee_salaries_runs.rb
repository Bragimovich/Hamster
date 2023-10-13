# frozen_string_literal: true

class Runs < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :usa_raw])
  include Hamster::Granary
  
  self.table_name = 'iowa_state_employee_salaries_runs'
end
