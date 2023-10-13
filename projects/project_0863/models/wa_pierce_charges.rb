# frozen_string_literal: true
class InmateCharges < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'wa_pierce_charges'
  self.inheritance_column = :_type_disabled
end
