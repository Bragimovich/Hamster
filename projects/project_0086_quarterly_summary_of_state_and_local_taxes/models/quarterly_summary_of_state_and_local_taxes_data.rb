# frozen_string_literal: true

class QuarterlySummaryOfStateAndLocalTaxes < ActiveRecord::Base
  establish_connection(Storage[host: :db13, db: :usa_raw])
  include Hamster::Granary
  self.table_name = 'quarterly_summary_of_state_and_local_taxes_data'
end
