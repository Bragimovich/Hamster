# frozen_string_literal: true
class PalmBeachInmatesId < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'fl_palmbeach_inmate_ids'
  self.inheritance_column = :_type_disabled
end
