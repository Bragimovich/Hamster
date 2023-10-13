class US_ice_cl < ActiveRecord::Base
  self.table_name = 'us_ice_categories_article_links'
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :press_releases])
end


