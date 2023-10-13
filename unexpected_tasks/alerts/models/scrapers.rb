class Scrapers < ActiveRecord::Base
  self.table_name = 'scrapers'
  establish_connection(Storage[host: :db02, db: :hle_resources])
end

