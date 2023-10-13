# frozen_string_literal: true
class MIRAWReceipts < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :raw_contributions])
  self.table_name = 'MI_RAW_receipts'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
