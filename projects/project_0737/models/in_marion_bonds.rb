# frozen_string_literal: true
class InMarionBonds < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'in_marion_bonds'
  self.inheritance_column = :_type_disabled
end
