# frozen_string_literal: true

class PaCampaignFinanceContributionsNewCsv < ActiveRecord::Base
  self.table_name = 'pa_campaign_finance_contributions_new_csv'
  establish_connection(Storage[host: :db13, db: :pa_raw])
  # establish_connection(Storage[host: :localhost, db: :usa_raw])
  self.logger = Logger.new(STDOUT)
  self.inheritance_column = :_type_disabled
end
