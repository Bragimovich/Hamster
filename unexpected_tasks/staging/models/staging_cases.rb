class StagingCases < ActiveRecord::Base
  self.table_name = 'cases'
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :us_courts_staging])
end
