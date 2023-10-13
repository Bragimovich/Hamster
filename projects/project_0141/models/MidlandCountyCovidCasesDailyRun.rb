require 'strip_attributes'

class MidlandCountyCovidCasesDailyRun < ActiveRecord::Base
  strip_attributes
  self.table_name = 'midland_county_covid_cases_daily_run'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end
