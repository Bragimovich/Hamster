# frozen_string_literal: true

class Dea < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  self.table_name = 'us_dept_dea'
  establish_connection(Storage[host: :db02, db: :press_releases])
end


class DeaTags < ActiveRecord::Base
  self.table_name = 'us_dept_dea_tags'
  establish_connection(Storage[host: :db02, db: :press_releases])
end

class DeaTagsArticleLinks < ActiveRecord::Base
  self.table_name = 'us_dept_dea_tags_article_links'
  establish_connection(Storage[host: :db02, db: :press_releases])
end