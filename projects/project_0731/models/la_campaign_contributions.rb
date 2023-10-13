# frozen_string_literal: true
class LaCampaignCont < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :raw_contributions])
  self.table_name = 'la_campaign_contributions'
  self.inheritance_column = :_type_disabled
end
