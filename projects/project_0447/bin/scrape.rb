# frozen_string_literal: true

require_relative '../lib/manager'

def scrape(options)
  begin
    manager = Manager.new
    if options[:download]
      manager.download
      manager.store
    elsif options[:download_archive]
      manager.download_archive
      manager.store_archive
    end
  rescue Exception => e
    Hamster.logger.error("Error: #{e.full_message}")
    report(to: 'U03HBFA4P3M', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
