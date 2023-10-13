# frozen_string_literal: true

class MidlandCountyCovidCases < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  include Hamster::Granary

  self.table_name = 'midland_county_covid_cases_biweekly_reports'
end
