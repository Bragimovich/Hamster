# frozen_string_literal: true

class AzEnrollment < ActiveRecord::Base
  self.table_name = 'az_enrollment'
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
end