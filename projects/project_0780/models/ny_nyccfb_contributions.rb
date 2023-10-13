# frozen_string_literal: true
class NyCont < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :raw_contributions])
  self.table_name = 'ny_nyccfb_contributions'
  self.inheritance_column = :_type_disabled
end
