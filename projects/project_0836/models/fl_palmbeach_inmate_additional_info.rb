# frozen_string_literal: true
class PalmBeachInmatesAdditional < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'fl_palmbeach_inmate_additional_info'
  self.inheritance_column = :_type_disabled
end
