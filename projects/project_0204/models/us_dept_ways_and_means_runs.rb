# frozen_string_literal: true

class UsDeptWaysAndMeansRuns < ActiveRecord::Base
  self.table_name = 'us_dept_ways_and_means_runs'
  establish_connection(Storage[host: :db02, db: :press_releases])
end
