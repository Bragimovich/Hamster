# frozen_string_literal: true

class PrlogCategoriesArticleLinks < ActiveRecord::Base
  self.table_name = 'prlog_categories_article_links'
  establish_connection(Storage[host: :db02, db: :press_releases])
end
