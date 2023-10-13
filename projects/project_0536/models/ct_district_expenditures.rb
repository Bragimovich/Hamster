class CtDistrictExpenditure < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
  self.table_name = 'ct_districts_expenditures'
end
