# frozen_string_literal: true

require_relative '../lib/us_doj_ojp_manager'

def scrape(options)
  begin
    manager = UsDojOjpManager.new
    if options[:download]
      manager.download
    elsif options[:store]
      manager.store
    end
  rescue Exception => e
    Hamster.logger.error("Error: #{e.full_message}")
    report(to: 'U03HBFA4P3M', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
