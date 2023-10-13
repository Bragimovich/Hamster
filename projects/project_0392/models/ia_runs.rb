class IARuns < ActiveRecord::Base
  self.table_name = 'ia_ac_runs'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

