# frozen_string_literal: true

require_relative '../lib/us_eeoc_scraper'

def scrape(options)
  begin
    mian_class_obj = UsEeocScraper.new
    mian_class_obj.press_release_scraper
  rescue Exception => e
   report(to: 'Muhammad Adeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end  
end
