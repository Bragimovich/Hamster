# frozen_string_literal: true
class LaCampaignExp < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :raw_contributions])
  self.table_name = 'la_campaign_expenditures'
  self.inheritance_column = :_type_disabled
end
