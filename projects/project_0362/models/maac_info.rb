class MAACInfo < ActiveRecord::Base
  self.table_name = 'maac_case_info'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

