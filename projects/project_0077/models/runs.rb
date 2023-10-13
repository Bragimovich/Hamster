# frozen_string_literal: true

class Runs < ActiveRecord::Base
  self.table_name = 'chicago_crime_statistics_runs'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end
