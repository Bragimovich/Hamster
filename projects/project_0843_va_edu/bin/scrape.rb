# frozen_string_literal: true

require_relative '../lib/manager'

def scrape(options)
  
  year = options[:year]
  if year.nil?
    year = Date.today.year
  end
  
  Hamster.report(to: 'Frank Rao', message: "Task #0843 - started running.")

  manager = Manager.new
  if options[:store]
    # manager.store_general_info
    # manager.store_enrollment
    # manager.store_discipline
    # manager.store_finances_receipts
    # manager.store_finances_expenditures
    # manager.store_finances_salaries
  end

  Hamster.report(to: 'Frank Rao', message: "Task #0843 - finished running.")
  
rescue StandardError => e
  Hamster.logger.error "#{e}".red
  Hamster.logger.error e.backtrace
  Hamster.logger.error "####################################".red
  Hamster.report(to: 'Frank Rao', message: "##{Hamster.project_number} | #{e}", use: :slack)
end
