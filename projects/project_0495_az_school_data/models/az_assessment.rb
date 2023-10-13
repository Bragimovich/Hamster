# frozen_string_literal: true

class AzAssessment < ActiveRecord::Base
  self.table_name = 'az_assessment'
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
end