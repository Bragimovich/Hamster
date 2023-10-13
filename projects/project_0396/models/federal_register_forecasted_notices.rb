# frozen_string_literal: true

class FederalRegisterForecastedNotices < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :press_releases])
  
  self.table_name = 'federal_register_forecasted_notices'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
  