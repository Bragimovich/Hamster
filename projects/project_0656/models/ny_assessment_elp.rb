# frozen_string_literal: true
class NyElp < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
  self.table_name = 'ny_assessment_elp'
  self.inheritance_column = :_type_disabled
end
