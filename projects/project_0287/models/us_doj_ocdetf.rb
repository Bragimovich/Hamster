class US_doj < ActiveRecord::Base
  self.table_name = 'us_doj_ocdetf'
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :press_releases])
end

