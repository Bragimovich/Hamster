# frozen_string_literal: true
class GaGwinnettImmatesIds < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'ga_gwinnett_immate_ids'
  self.inheritance_column = :_type_disabled
end
