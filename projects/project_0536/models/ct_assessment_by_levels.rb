class CtSchoolAssessmentByLevels < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
  self.table_name = 'ct_assessment_by_levels'
end
