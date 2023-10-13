# frozen_string_literal: true

class OrOregonCharges < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'or_oregon_charges'
  self.inheritance_column = :_type_disabled
end
 