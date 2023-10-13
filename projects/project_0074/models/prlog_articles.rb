# frozen_string_literal: true

class PrlogArticles < ActiveRecord::Base
  self.table_name = 'prlog_articles'
  establish_connection(Storage[host: :db02, db: :press_releases])
end


class PrlogArticlesBackup < ActiveRecord::Base
  self.table_name = 'prlog_articles_backup'
  establish_connection(Storage[host: :db02, db: :press_releases])
end