class LeapSubgroup < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
  self.table_name = 'la_assessment_leap_subgroup'
  self.inheritance_column = :_type_disabled
end
