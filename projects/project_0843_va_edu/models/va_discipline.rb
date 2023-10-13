# frozen_string_literal: true

class VaDiscipline < ActiveRecord::Base
  self.table_name = 'va_discipline'
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
  self.inheritance_column = :_type_disabled
end
