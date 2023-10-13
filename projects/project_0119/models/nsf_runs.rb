# frozen_string_literal: true

class NSFRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :press_releases])
  include Hamster::Granary
  
  self.table_name = 'nsf_runs'
  self.logger = Logger.new(STDOUT)
end
