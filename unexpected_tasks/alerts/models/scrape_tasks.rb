class ScrapeTasks < ActiveRecord::Base
  self.table_name = 'scrape_tasks'
  establish_connection(Storage[host: :db02, db: :lokic])
end

