# frozen_string_literal: true
class PalmBeachInmatesArrests < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'fl_palmbeach_arrests'
  self.inheritance_column = :_type_disabled
end
