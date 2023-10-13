class VtScCaseAdditionalInfo < ActiveRecord::Base
  
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'vt_sc_case_additional_info'
end
