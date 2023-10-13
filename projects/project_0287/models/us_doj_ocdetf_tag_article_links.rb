class US_doj_tag_article < ActiveRecord::Base
  self.table_name = 'us_doj_ocdetf_tag_article_links'
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :press_releases])
end

