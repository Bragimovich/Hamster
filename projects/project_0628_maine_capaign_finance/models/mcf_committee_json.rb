# frozen_string_literal: true

class MCFCommitteeJson < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'maine_campaign_finance_committees_json'
end
  