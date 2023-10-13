# frozen_string_literal: true
class InAdministrators < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
  self.table_name = 'in_administrators'
  self.inheritance_column = :_type_disabled
end
