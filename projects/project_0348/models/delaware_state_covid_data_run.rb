# frozen_string_literal: true

class Runs < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])

  self.table_name = 'delaware_state_covid_data_run'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)

  def self.last_run
    self.all.to_a.last
  end

end
  