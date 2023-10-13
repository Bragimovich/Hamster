# frozen_string_literal: true
class LaCampaignPac < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :raw_contributions])
  self.table_name = 'la_campaign_political_action_committees'
  self.inheritance_column = :_type_disabled
end
