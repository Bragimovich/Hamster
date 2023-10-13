# frozen_string_literal: true
class GaGwinnettImmates < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'ga_gwinnett_immates'
  self.inheritance_column = :_type_disabled
end
