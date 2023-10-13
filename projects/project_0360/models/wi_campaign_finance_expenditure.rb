# frozen_string_literal: true

require_relative 'wi_campaign_financeable'
class WiCampaignFinanceExpenditure < ActiveRecord::Base
  include WiCampaignFinanceable
end
