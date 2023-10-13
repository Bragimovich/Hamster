# frozen_string_literal: true
class TxInfo < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])

  self.table_name = 'tx_jcdc_case_info'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
