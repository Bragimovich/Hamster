# frozen_string_literal: true

class GasBuddyRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'gasbuddy_v2_gas_stations_runs'
end
