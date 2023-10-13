# frozen_string_literal: true

class NewTennesseeCampaignFinanceReports < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'new_tennessee_campaign_finance_reports'
  self.inheritance_column = :_type_disabled
end
