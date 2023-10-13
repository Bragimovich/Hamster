class StagingActivities < ActiveRecord::Base
  self.table_name = 'activities'
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :us_courts_staging])
end
