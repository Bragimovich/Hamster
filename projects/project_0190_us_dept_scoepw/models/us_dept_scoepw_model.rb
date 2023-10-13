# frozen_string_literal: true

class SCOEPWNews < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  self.table_name = 'us_dept_scoepw_news'
  establish_connection(Storage[host: :db02, db: :press_releases])
end


class SCOEPWPress < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  self.table_name = 'us_dept_scoepw_press_releases'
  establish_connection(Storage[host: :db02, db: :press_releases])
end