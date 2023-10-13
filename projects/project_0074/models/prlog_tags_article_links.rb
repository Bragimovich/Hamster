# frozen_string_literal: true

class PrlogTagsArticleLinks < ActiveRecord::Base
  self.table_name = 'prlog_tags_article_links'
  establish_connection(Storage[host: :db02, db: :press_releases])
end
