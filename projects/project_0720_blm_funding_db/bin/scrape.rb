# frozen_string_literal: true
require_relative '../lib/manager'
LOGFILE = "project_720.log"

def scrape(options)
  begin
    manager = Manager.new
    if options[:auto]
      manager.download_and_store_general
      manager.store_details
      manager.store_recipients
      manager.store_hq_locations
      manager.update_md5_hash
    end
  rescue Exception => e
    Hamster.report(to: Manager::FRANK_RAO, message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end 
end
