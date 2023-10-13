# frozen_string_literal: true

class FederalRegisterForecastedNoticesRun < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :press_releases])

  self.table_name = 'federal_register_forecasted_notices_run'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)

  def self.last_run
    self.all.to_a.last
  end

end