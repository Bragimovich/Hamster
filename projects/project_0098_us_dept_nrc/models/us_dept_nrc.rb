# frozen_string_literal: true

class UsDeptNRC < ActiveRecord::Base
  self.table_name = 'us_dept_nrc'
  establish_connection(Storage[host: :db02, db: :press_releases])
end
