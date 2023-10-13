# frozen_string_literal: true
class NyExp < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
  self.table_name = 'ny_expenditures'
  self.inheritance_column = :_type_disabled
end
