# frozen_string_literal: true
class FlPolkInmates < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'fl_polk_inmates'
  self.inheritance_column = :_type_disabled
end
