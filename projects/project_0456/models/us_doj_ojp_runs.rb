# frozen_string_literal: true
class UsDoOjpRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :press_releases])

  self.table_name = 'us_doj_ojp_runs'
  self.inheritance_column = :_type_disabled
end
