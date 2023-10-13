
class La1cAcCaseInfo < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'la_1c_ac_case_info'
  self.inheritance_column = :_type_disabled
end