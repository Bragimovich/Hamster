# frozen_string_literal: true

class NIFACategoriesArticleLinks < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :press_releases])
  include Hamster::Granary
  
  self.table_name = 'ne_invest_finance_authority_categories_article_links'
  self.logger = Logger.new(STDOUT)

end
