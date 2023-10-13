# frozen_string_literal: true
class GaGwinnettCharges < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'ga_gwinnett_charges'
  self.inheritance_column = :_type_disabled
end
