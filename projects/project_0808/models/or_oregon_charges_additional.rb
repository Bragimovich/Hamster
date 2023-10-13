# frozen_string_literal: true

class OrOregonChargesAdditional < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'or_oregon_charges_additional'
  self.inheritance_column = :_type_disabled
end
 