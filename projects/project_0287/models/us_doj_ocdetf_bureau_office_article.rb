class US_doj_office < ActiveRecord::Base
  self.table_name = 'us_doj_ocdetf_bureau_office_article'
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :press_releases])
end

