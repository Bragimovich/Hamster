# frozen_string_literal: true
require_relative '../lib/manager'

def scrape(options)
  Hamster.report(to: Manager::WILLIAM_DEVRIES, message: "#{@project_number} Started", use: :slack)
  begin
    manager = Manager.new
    if options[:auto]
      year = options[:year]
      if year.nil?
        year = Date.today.year
      end
      manager.download_and_store(year)
    end
  rescue Exception => e
    Hamster.report(to: Manager::WILLIAM_DEVRIES, message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end 
end
