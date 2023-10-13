class DATXInfo < ActiveRecord::Base
  self.table_name = 'da_tx_case_info'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

