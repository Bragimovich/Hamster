# frozen_string_literal: true

require_relative 'wi_campaign_financeable'
class WiCampaignFinanceRun < ActiveRecord::Base
  include WiCampaignFinanceable
end
