require 'strip_attributes'

class MidlandCountyCovidCasesDaily < ActiveRecord::Base
  strip_attributes
  self.table_name = 'midland_county_covid_cases_daily'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end
