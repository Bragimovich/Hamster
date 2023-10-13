class DATXActivities < ActiveRecord::Base
  self.table_name = 'da_tx_case_activities'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

