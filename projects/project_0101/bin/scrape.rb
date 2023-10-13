# frozen_string_literal: true

require_relative '../lib/us_aid_scrape'

def scrape(options)
  begin

    scraper = UsAidScrape.new
    if options[:active]
      scraper.press_release_scraper
    elsif options[:archive]
      scraper.news_archive_scraper
    end
  rescue Exception => e
    report(to: 'Muhammad Adeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
