# frozen_string_literal: true
class PalmBeachInmatesAddresses < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'fl_palmbeach_inmate_addresses'
  self.inheritance_column = :_type_disabled
end
