# frozen_string_literal: true

require_relative '../models/cdc_weekly_counts_of_death_by_jurisdiction_and_cause_of_death'

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
