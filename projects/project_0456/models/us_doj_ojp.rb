# frozen_string_literal: true
class UsDojOjp < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :press_releases])

  self.table_name = 'us_doj_ojp'
  self.inheritance_column = :_type_disabled
end
