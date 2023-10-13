# frozen_string_literal: true
require_relative '../lib/manager'
LOGFILE = "project_628.log"

def scrape(options)
  begin
    year = options[:year] || Date.today().year
    manager = Manager.new

    if options[:download]
      manager.download(year)
    end
    if options[:store]
      manager.store(year)
    end
    if options[:clear]
      manager.clear_files(year)
    end

  rescue Exception => e
    Hamster.report(to: Manager::FRANK_RAO, message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end 
end
