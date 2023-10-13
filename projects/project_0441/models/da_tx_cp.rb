class DATXParty < ActiveRecord::Base
  self.table_name = 'da_tx_case_party'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

