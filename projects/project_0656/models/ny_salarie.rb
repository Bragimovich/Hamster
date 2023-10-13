# frozen_string_literal: true
class NySalarie < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
  self.table_name = 'ny_teachers_salaries'
  self.inheritance_column = :_type_disabled
end
