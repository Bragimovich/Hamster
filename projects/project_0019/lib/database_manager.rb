# frozen_string_literal: true

require_relative '../models/cdc_weekly_counts_of_deaths_by_jurisdiction_race_hispanic_origin'

# This class perform all operations with database (CRUD)

class DatabaseManager
  def self.save_item(item)
    item.save
  rescue StandardError => e
    p e
    p e.backtrace
    raise
  end
end
