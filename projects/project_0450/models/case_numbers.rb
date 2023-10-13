class CaseNumbers < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'illinois_court_case_numbers'
  self.inheritance_column = :_type_disabled
end
