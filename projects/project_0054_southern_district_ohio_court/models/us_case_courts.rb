# frozen_string_literal: true

class UsCaseCourts < ActiveRecord::Base
  self.table_name = 'OHSD_courts'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  # establish_connection(Storage[host: :localhost, db: :us_court_cases])
  self.logger = Logger.new(STDOUT)
end
