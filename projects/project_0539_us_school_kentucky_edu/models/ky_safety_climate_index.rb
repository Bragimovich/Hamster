# frozen_string_literal: true
class KySafetyClimateIndex < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
  self.table_name = 'ky_safety_climate_index'
end
