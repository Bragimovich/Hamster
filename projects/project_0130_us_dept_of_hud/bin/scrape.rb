# frozen_string_literal: true

require_relative '../lib/scraper.rb'
require_relative '../lib/scraper_archive.rb'

def scrape(options)
  begin
    if options[:active]
      Scraper.new.main
    elsif options[:archive]
      ScraperArchive.new.main
    end
  rescue Exception => e
    report(to: 'Aqeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
