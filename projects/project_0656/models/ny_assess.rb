# frozen_string_literal: true
class NyAssess < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
  self.table_name = 'ny_assessment'
  self.inheritance_column = :_type_disabled
end
