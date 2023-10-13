# frozen_string_literal: true
class GaGwinnettHoldingFacilitiesAddresses < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'ga_gwinnett_holding_facilities_addresses'
  self.inheritance_column = :_type_disabled
end
