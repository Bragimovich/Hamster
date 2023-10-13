# frozen_string_literal: true

class SchoolAlias < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :us_sports_raw])
  self.table_name = 'school_aliases'
  self.inheritance_column = :_type_disabled
end
  