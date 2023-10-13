class LaCampaignExpenditures < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'la_campaign_expenditures'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
