# frozen_string_literal: true

require_relative 'wi_campaign_financeable'
class WiCampaignFinanceCommittee < ActiveRecord::Base
  include WiCampaignFinanceable
end
