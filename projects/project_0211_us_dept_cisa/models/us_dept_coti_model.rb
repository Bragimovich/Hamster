# frozen_string_literal: true

class Cisa < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  self.table_name = 'us_dept_cisa'
  establish_connection(Storage[host: :db02, db: :press_releases])
end


class CisaCategories < ActiveRecord::Base
  self.table_name = 'us_dept_cisa_categories'
  establish_connection(Storage[host: :db02, db: :press_releases])
end

class CisaCategoriesArticleLinks < ActiveRecord::Base
  self.table_name = 'us_dept_cisa_categories_article_links'
  establish_connection(Storage[host: :db02, db: :press_releases])
end

class CisaTags < ActiveRecord::Base
  self.table_name = 'us_dept_cisa_tags'
  establish_connection(Storage[host: :db02, db: :press_releases])
end

class CisaTagsArticleLinks < ActiveRecord::Base
  self.table_name = 'us_dept_cisa_tags_article_link'
  establish_connection(Storage[host: :db02, db: :press_releases])
end