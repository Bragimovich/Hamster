# frozen_string_literal: true

class SCOEMRDemocratic < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  self.table_name = 'us_dept_scoenr_democratic'
  establish_connection(Storage[host: :db02, db: :press_releases])
end


class SCOEMRRepublican < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  self.table_name = 'us_dept_scoenr_republican'
  establish_connection(Storage[host: :db02, db: :press_releases])
end