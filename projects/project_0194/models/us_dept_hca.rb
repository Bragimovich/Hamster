# frozen_string_literal: true
class UsDeptHca < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :press_releases])
  self.table_name = 'us_dept_hca'
  self.inheritance_column = :_type_disabled
end
