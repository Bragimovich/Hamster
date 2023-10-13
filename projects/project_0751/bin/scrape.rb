# frozen_string_literal: true
require_relative '../lib/manager'

def scrape(options)
  begin
    manager = Manager.new
    report to: 'Hatri', message: "project 0751: Start Scraping"

    if options[:download]
      manager.download
      report to: 'Hatri', message: "project 0751: Finish Downloading files"
    elsif options[:store]
      manager.store
      report to: 'Hatri', message: "project 0751: Finish storing to database"
    elsif options[:auto]
      manager.download
      manager.store
      report to: 'Hatri', message: "project 0751: Finish Downloading files and storing to database"
    else
      manager.download
      manager.store
      report to: 'Hatri', message: "project 0751: Finish Downloading files and storing to database"
    end
  rescue StandardError => e
    report to: 'Hatri', message: "project 0751: #{e.full_message}"
  end
end
