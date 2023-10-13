# frozen_string_literal: true

require_relative '../models/chicago_public_schools_suppliers_payments'

# This class perform all operations with database (CRUD)
class DatabaseManager
  def self.save_item(item)
    item.save
  rescue StandardError => e
    Hamster.report(to: 'dmitiry.suschinsky', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nERROR\n#{e.full_message}", use: :slack)
  end
end
