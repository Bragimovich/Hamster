# frozen_string_literal: true
class NyErieInmatesIds < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'ny_erie_inmate_ids'
  self.inheritance_column = :_type_disabled
end
