# frozen_string_literal: true

class NcRawNcvoter < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :raw_contributions])
  self.table_name = 'NC_RAW_NCVOTER'
  self.inheritance_column = :_type_disabled
end
