# frozen_string_literal: true
class MilwaukeeCounty < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.inheritance_column = :_type_disabled
  self.table_name = 'milwaukee_county_covid_related_deaths'
  self.logger = Logger.new(STDOUT)
end
