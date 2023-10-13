# frozen_string_literal: true
class KySchoolsAssessment < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
  self.table_name = 'ky_schools_assessment'
  self.logger = Logger.new(STDOUT)
end
