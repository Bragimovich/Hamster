class AlCollegeCareerReadinesss < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
  self.table_name = 'al_college_career_readiness'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
  include Hamster::Granary
end