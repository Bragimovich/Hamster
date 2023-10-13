# frozen_string_literal: true

class MinnesotaCampaignFinanceRun < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_fin_cc_raw])
  self.table_name = 'minnesota_campaign_finance_runs'
  self.inheritance_column = :_type_disabled
end
