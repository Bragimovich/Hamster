# frozen_string_literal: true

require_relative '../models/ct_saac_case_runs'
require_relative '../models/paid_proxies'


# This class perform all operations with database (CRUD)
class DatabaseManager
  def self.save_item(item)
    item.save
  rescue StandardError => e
    p e
    p e.backtrace
  end
end
