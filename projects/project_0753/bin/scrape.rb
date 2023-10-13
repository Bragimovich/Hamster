# frozen_string_literal: true
require_relative '../lib/manager'

def scrape(options)
  begin
    Manager.new.run_script 
  rescue Exception => e
    Hamster.logger.error("Error: #{e.full_message}")
    report(to: 'U04MHBYU5R9', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
