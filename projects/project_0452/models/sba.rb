# frozen_string_literal: true

class Sba < ActiveRecord::Base
  self.table_name = 'sba'
  establish_connection(Storage[host: :db02, db: :press_releases])
  self.inheritance_column = :_type_disabled
end
