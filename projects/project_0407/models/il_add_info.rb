class ILAddInfo < ActiveRecord::Base
  self.table_name = 'il_saac_case_additional_info'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

