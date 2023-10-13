# frozen_string_literal: true
class NyMonroeInmates < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'ny_monroe_inmates'
  self.inheritance_column = :_type_disabled
end
