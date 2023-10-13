# frozen_string_literal: true

class DB02Processlists < ActiveRecord::Base
  self.establish_connection(Storage[host: :db01, db: :db_audit])
  self.table_name = 'db02_processlists'
end

class ScrapeTasksAttachedTables < ActiveRecord::Base
  self.establish_connection(Storage[host: :db02, db: :hle_resources])
  self.table_name = 'scrape_tasks_attached_tables'
end

class ScrapeTasksAttachedTablesSentCounter < ActiveRecord::Base
  self.establish_connection(Storage[host: :db02, db: :hle_resources])
  self.table_name = 'scrape_tasks_attached_tables_sent_counter'
end
