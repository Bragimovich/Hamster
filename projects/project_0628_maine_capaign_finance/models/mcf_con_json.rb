# frozen_string_literal: true

class MCFConJson < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'maine_campaign_finance_contributions_json'
end
