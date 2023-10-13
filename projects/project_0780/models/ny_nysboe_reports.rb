# frozen_string_literal: true
class NyRep < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :raw_contributions])
  self.table_name = 'ny_nysboe_reports'
  self.inheritance_column = :_type_disabled
end
