# frozen_string_literal: true

class UsDeptFccCategoriesArticleLinks < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :press_releases])
  include Hamster::Granary
  
  self.table_name = 'us_dept_fcc_categories_article_links'
  self.inheritance_column = :_type_disabled
end
