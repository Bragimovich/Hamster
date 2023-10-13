# frozen_string_literal: true

class GreenvilleRuns < ActiveRecord::Base
  establish_connection(Storage.use(host: :db01, db: :us_court_cases))
  self.table_name = 'greenville_runs'
  include Hamster::Granary
end
