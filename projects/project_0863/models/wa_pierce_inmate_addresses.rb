# frozen_string_literal: true
class InmateAddresses < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'wa_pierce_inmate_addresses'
  self.inheritance_column = :_type_disabled
end
