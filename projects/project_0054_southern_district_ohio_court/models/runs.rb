# frozen_string_literal: true

class Runs < ActiveRecord::Base
  self.table_name = 'OHSD_runs'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  # establish_connection(Storage[host: :localhost, db: :us_court_cases])
end
