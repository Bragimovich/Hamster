# frozen_string_literal: true

require_relative '../lib/manager'
LOGFILE = "scrape_log_file.log"

def scrape(options)
  begin
    manager = Manager.new
    if options[:download]
      manager.download
    elsif options[:store]
      manager.store
    elsif options[:activity_page]
      manager.activity_page
    elsif options[:activity_page_store]
      manager.activity_page_store
    end
  rescue Exception => e
    puts e.full_message
    report(to: 'Raza Aslam', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end 
end
