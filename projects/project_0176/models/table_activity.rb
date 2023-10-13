# frozen_string_literal: true

class TableActivity < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  
  self.table_name = 'mi_saac_case_activities'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
  