class US_oirf_tag_link < ActiveRecord::Base
  self.table_name = 'us_dept_dos_oirf_tags_article_links'
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :press_releases])
end

