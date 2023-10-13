# frozen_string_literal: true

class TxEmpSalary < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'tx_employee_salary'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
