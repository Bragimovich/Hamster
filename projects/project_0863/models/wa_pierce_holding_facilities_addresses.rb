# frozen_string_literal: true
class InmateFacilitiesAddress < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'wa_pierce_holding_facilities_addresses'
  self.inheritance_column = :_type_disabled
end
