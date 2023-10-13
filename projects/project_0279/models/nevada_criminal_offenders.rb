# frozen_string_literal: true
class NevadaCriminalOffenders < ActiveRecord::Base
  establish_connection(Storage[host: :db13, db: :usa_raw])
  self.table_name = 'nevada_criminal_offenders'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
