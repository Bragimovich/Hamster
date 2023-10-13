class RawActivitiesSaac < ActiveRecord::Base
  self.table_name = 'us_saac_case_activities'
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :us_courts])
end
