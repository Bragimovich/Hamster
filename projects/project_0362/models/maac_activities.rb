class MAACActivities < ActiveRecord::Base
  self.table_name = 'maac_case_activities'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

