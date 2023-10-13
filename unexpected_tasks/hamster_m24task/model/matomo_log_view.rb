class MatomoLogView < ActiveRecord::Base
  establish_connection(Storage.use(host: :dbRS, db: :mat))
  self.table_name = 'matomo_site'
end
