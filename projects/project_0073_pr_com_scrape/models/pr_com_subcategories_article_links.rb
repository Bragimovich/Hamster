# frozen_string_literal: true

class PrComSubcategoriesArticleLinks < ActiveRecord::Base
  self.table_name = 'pr_com_subcategories_article_links'
  establish_connection(Storage[host: :db02, db: :press_releases])
  # establish_connection(Storage[host: :localhost, db: :press_releases])
  self.logger = Logger.new(STDOUT)
end
