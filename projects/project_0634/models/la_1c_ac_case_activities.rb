class La1cAcCaseActivities < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'la_1c_ac_case_activities'
  self.inheritance_column = :_type_disabled
end