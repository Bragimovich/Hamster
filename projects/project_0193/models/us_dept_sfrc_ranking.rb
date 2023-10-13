class US_dc_ranking < ActiveRecord::Base
  self.table_name = 'us_dept_sfrc_ranking'
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :press_releases])
end
