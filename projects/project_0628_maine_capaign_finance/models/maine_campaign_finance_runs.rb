# frozen_string_literal: true
class MaineCampaignFinanceRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'maine_campaign_finance_runs'
  self.logger = Logger.new(STDOUT)
end
