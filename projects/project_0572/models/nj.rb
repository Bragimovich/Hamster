# frozen_string_literal: true
class NjState < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'nj_state_employees_salaries'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
