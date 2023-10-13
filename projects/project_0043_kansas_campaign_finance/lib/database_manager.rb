# frozen_string_literal: true

require_relative '../models/kansas_campaign_contributors'
require_relative '../models/kansas_campaign_expenditures'
require_relative '../models/kansas_campaign_finance_runs'

# This class perform all operations with database (CRUD)
class DatabaseManager
  def self.save_item(item)
    item.save
  rescue StandardError => e
    Hamster.report(to: 'Dmitiry Suschinsky', message: "DB Error #43\n#{e}")
  end
end
