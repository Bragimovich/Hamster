class StagingCourts < ActiveRecord::Base
  self.table_name = 'courts'
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :us_courts_staging])
end
