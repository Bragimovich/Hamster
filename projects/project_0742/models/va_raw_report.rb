# frozen_string_literal: true
class VaRawReport < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :raw_contributions])
  self.table_name = 'VA_RAW_REPORT'
  self.inheritance_column = :_type_disabled
end
