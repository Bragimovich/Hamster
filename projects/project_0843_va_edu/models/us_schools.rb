# frozen_string_literal: true

class UsSchools < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  self.table_name = 'us_schools'
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
end
