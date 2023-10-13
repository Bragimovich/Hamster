# frozen_string_literal: true

class Fdic < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :press_releases])

  self.table_name = 'fdic'
  self.inheritance_column = :_type_disabled
end
