# frozen_string_literal: true
class TxRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])

  self.table_name = 'tx_jcdc_case_runs'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
