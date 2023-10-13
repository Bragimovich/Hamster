# frozen_string_literal: true

require_relative '../lib/manager'

def scrape(options)
  begin
    manager = Manager.new
    if options[:download_individual]
      manager.download_individual_option
    elsif options[:download_business]
      manager.download_business_option
    elsif options[:store]
      manager.store
    end
  rescue Exception => e
    Hamster.logger.error(e.full_message)
    Hamster.report(to: 'UD1LWNPEW', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
