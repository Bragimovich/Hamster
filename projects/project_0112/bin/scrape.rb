# frozen_string_literal: true

require_relative '../lib/us_doj_scraper'
require_relative '../lib/us_doj_archive_scraper'

def scrape(options)
  begin
    if options[:active]
      scraper = UsDojScraper.new
      scraper.press_release_scraper
    elsif options[:archive]
      scraper = UsDojArchiveScraper.new
      scraper.news_archive_scraper
    end
  rescue Exception => e
    report(to: 'Muhammad Adeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end  
end
