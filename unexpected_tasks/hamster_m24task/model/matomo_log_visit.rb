class MatomoLogVisit < ActiveRecord::Base
  self.table_name = 'matomo_log_visit'
  establish_connection(Storage.use(host: :dbRS, db: :mat))
end
