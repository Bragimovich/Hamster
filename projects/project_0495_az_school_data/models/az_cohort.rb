# frozen_string_literal: true

class AzCohort < ActiveRecord::Base
  self.table_name = 'az_cohort'
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
end