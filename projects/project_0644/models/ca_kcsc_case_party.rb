class CaKcscCaseParty < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name         = 'ca_kcsc_case_party'
  self.inheritance_column = :_type_disabled
end
