class DeAssessment < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
  self.table_name = 'de_assessment'
  self.inheritance_column = :_type_disabled
end
