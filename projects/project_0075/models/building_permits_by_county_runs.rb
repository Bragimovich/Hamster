# frozen_string_literal: true

class class BuildingPermitsRuns < ActiveRecord::Base
  include Hamster::Loggable
  establish_connection(Storage[host: :db01, db: :usa_raw])
  include Hamster::Granary
  
  self.table_name = 'building_permits_by_county_runs'
end
