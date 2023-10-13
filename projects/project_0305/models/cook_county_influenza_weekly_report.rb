# frozen_string_literal: true
class CookCountryInfluenzaReport < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'cook_county_influenza_weekly_report'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new($stdout)
end
