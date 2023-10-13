# frozen_string_literal: true

class UsDeptFrs < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :press_releases])
  include Hamster::Granary
  self.table_name = 'us_dept_frs'
  self.logger = Logger.new(STDOUT)
end

class UsDeptFrsRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :press_releases])
  include Hamster::Granary
  self.table_name = 'us_dept_frs_runs'
  self.logger = Logger.new(STDOUT)
end

class UsDeptFrsCategories < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :press_releases])
  include Hamster::Granary
  self.table_name = 'us_dept_frs_categories'
  self.logger = Logger.new(STDOUT)
end

class UsDeptFrsCategoriesArticleLinks < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :press_releases])
  include Hamster::Granary
  self.table_name = 'us_dept_frs_categories_article_links'
  self.logger = Logger.new(STDOUT)
end
