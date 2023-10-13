# frozen_string_literal: true
class NyErieInmates < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'ny_erie_inmates'
  self.inheritance_column = :_type_disabled
end
