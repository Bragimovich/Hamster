class IRSStateOutflow < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :usa_raw])
  include Hamster::Granary

  self.table_name = 'IRS_state_outflow'
  self.logger = Logger.new(STDOUT)
end
