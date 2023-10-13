# frozen_string_literal: true

class DelawareStateCovidData < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])

  self.table_name = 'delaware_state_covid_data'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
  