# frozen_string_literal: true
class NationalAdress < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :raw_contributions])
  self.table_name = 'national_addresses'
  self.inheritance_column = :_type_disabled
end
