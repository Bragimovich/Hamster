# frozen_string_literal: true

class UsSenate < ActiveRecord::Base
  establish_connection(Storage[host: 'db01', db: :usa_raw])
  self.table_name = 'us_senate_financial_disclosures'
  self.inheritance_column = :_type_disabled
end
