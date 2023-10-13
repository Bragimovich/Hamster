# frozen_string_literal: true

class NewJerseySCCCsv < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
    
  self.table_name = 'new_jersey_state_campaign_contributions_csv'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
