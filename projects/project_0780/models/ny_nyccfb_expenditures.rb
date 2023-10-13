# frozen_string_literal: true
class NyExp < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :raw_contributions])
  self.table_name = 'ny_nyccfb_expenditures'
  self.inheritance_column = :_type_disabled
end
