# frozen_string_literal: true

class UsDeptHHS < ActiveRecord::Base
  self.table_name = 'us_dept_hhs'
  establish_connection(Storage[host: :db02, db: :press_releases])
end
