class MatomoLog < ActiveRecord::Base
  establish_connection(Storage.use(host: :db02, db: :seo))
  self.table_name = 'matomo_log'
end
