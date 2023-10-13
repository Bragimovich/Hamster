# frozen_string_literal: true

class Person < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :us_sports_raw])
  self.table_name = 'persons'
  self.inheritance_column = :_type_disabled
end
