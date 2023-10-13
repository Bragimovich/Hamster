# frozen_string_literal: true

require_relative '../lib/manager'

def scrape(options)
  begin
    manager = Manager.new
    if options[:download]
      manager.download
    elsif options[:store_case_numbers]
      manager.store_case_numbers
    elsif options[:store]
      manager.store
    elsif options[:store_party]
      manager.store_party
    end
  rescue Exception => e
    Hamster.logger.error("Error: #{e.full_message}")
    Hamster.report(to: 'U03HBFA4P3M', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
