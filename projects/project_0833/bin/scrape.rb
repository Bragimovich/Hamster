# frozen_string_literal: true

require_relative '../lib/manager'
def scrape(options)
  begin
    Hamster.report(to: 'U04JS3K201J', message: "project_0833: Started Scraping!")
    if options[:store]
      Manager.new.store
    else
      Manager.new.clear_files    
      Manager.new.scrape
    end
    Hamster.report(to: 'U04JS3K201J', message: "project_0833: Scraping Done!")
  rescue Exception => e
    Manager.new.clear
    Hamster.report(to: 'U04JS3K201J', message: "project_0833:\n#{e.full_message}")
  end
end

