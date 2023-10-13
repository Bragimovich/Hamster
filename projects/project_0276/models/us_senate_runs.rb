# frozen_string_literal: true

class UsSenateRuns < ActiveRecord::Base
  establish_connection(Storage[host: 'db01', db: :usa_raw])
  self.table_name = 'us_senate_financial_disclosures_runs'
  self.inheritance_column = :_type_disabled
end
