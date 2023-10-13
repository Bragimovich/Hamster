# frozen_string_literal: true
class LaCampaignCand < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :raw_contributions])
  self.table_name = 'la_campaign_candidates'
  self.inheritance_column = :_type_disabled
end
