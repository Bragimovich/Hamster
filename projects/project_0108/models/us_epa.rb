# frozen_string_literal: true

class UsEpa < ActiveRecord::Base
  self.table_name = 'us_epa'
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :press_releases])
end