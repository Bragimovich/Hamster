# frozen_string_literal: true

require_relative '../models/harris_county_tx_delinquent_tax_sale_property'

# This class perform all operations with database (CRUD)
class DatabaseManager
  def self.save_item(item)
    item.save
  rescue StandardError => e
    p e
    p e.backtrace
  end
end
