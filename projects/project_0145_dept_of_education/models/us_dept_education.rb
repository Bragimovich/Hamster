# frozen_string_literal: true

class UsDeptEducation < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  self.table_name = 'us_dept_education'
  establish_connection(Storage[host: :db02, db: :press_releases])
end


class UsDeptEducationTags < ActiveRecord::Base
  self.table_name = 'us_dept_education_tags'
  establish_connection(Storage[host: :db02, db: :press_releases])
end


class UsDeptEducationTagsArticle < ActiveRecord::Base
  self.table_name = 'us_dept_education_tags_article'
  establish_connection(Storage[host: :db02, db: :press_releases])
end
