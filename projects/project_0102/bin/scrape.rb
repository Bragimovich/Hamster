# frozen_string_literal: true

require_relative '../lib/us_dept_cftc_scrape'
require_relative '../lib/us_dept_cftc_categories_scrape'

def scrape(options)
  begin
    if options[:scraper]
      scraper = UsDeptCftcScrape.new
      scraper.press_release_scraper
    elsif options[:sync_categories]
      scraper_categories = UsDeptCftcCategoriesScrape.new
      scraper_categories.main
    end
  rescue Exception => e
   report(to: 'Muhammad Adeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end  
end
