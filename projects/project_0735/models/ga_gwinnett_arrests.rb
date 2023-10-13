# frozen_string_literal: true
class GaGwinnettArrests < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'ga_gwinnett_arrests'
  self.inheritance_column = :_type_disabled
end
