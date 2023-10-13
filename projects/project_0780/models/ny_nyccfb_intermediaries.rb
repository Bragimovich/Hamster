# frozen_string_literal: true
class NyInt < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :raw_contributions])
  self.table_name = 'ny_nyccfb_intermediaries'
  self.inheritance_column = :_type_disabled
end
