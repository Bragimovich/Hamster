class LaCampaignContributions < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'la_campaign_contributions'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
