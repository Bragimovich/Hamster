# frozen_string_literal: true

class UsDeptWaysAndMeansRuns < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :press_releases])
  include Hamster::Granary
  
  self.table_name = 'us_dept_ways_and_means_runs'
  self.logger = Logger.new(STDOUT)
end
