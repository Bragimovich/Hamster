# frozen_string_literal: true

class Coti < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  self.table_name = 'us_dept_coti'
  establish_connection(Storage[host: :db02, db: :press_releases])
end


class CotiCategories < ActiveRecord::Base
  self.table_name = 'us_dept_coti_categories'
  establish_connection(Storage[host: :db02, db: :press_releases])
end

class CotiCategoriesArticleLinks < ActiveRecord::Base
  self.table_name = 'us_dept_coti_categories_article_links'
  establish_connection(Storage[host: :db02, db: :press_releases])
end