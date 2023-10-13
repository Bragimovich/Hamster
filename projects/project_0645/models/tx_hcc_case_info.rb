class CaseInfo < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'tx_hcc_case_info'
  self.inheritance_column = :_type_disabled
end
