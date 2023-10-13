class RawCases < ActiveRecord::Base
  self.table_name = 'us_case_info'
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :us_courts])
end
