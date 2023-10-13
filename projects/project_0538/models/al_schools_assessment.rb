class AlSchoolsAssessment < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
  self.table_name = 'al_schools_assessment'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
  include Hamster::Granary
end