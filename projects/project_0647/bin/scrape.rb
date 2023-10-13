# frozen_string_literal: true
require_relative '../lib/manager'
LOGFILE = "project_647.log"

def scrape(options)
  begin
    manager = Manager.new
    if options[:download]
      manager.download
    elsif options[:download_archieve]
      manager.download_archieve
    elsif options[:store]
      manager.store
    end
  rescue Exception => e
    puts e.full_message
    Hamster.report(to: 'Muhammad Habib', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end 
end
