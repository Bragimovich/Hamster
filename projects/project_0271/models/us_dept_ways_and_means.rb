# frozen_string_literal: true

class UsDeptWaysAndMeans < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :press_releases])
  include Hamster::Granary
  
  self.table_name = 'us_dept_ways_and_means'
  self.logger = Logger.new(STDOUT)
end
