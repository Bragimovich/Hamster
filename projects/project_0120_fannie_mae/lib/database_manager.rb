# frozen_string_literal: true

require_relative '../models/fannie_mae'
require_relative '../models/fannie_mae_runs'


# This class perform all operations with database (CRUD)
class DatabaseManager
  def self.save_item(item)
    item.save
  rescue StandardError => e
    Hamster.report(to: 'dmitiry.suschinsky', message: "#120 Fannie Mae - DB exception: #{e}!")
  end
end
