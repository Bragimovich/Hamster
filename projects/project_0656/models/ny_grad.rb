# frozen_string_literal: true
class NyGrad < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
  self.table_name = 'ny_graduation'
  self.inheritance_column = :_type_disabled
end
