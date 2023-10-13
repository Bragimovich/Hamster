# frozen_string_literal: true

class BLM < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  self.table_name = 'us_dept_blm'
  establish_connection(Storage[host: :db02, db: :press_releases])
end
