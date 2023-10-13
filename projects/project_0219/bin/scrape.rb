# frozen_string_literal: true

require_relative '../lib/us_chairman_scraper.rb'

def scrape(options)
  begin
    UsChairmanScraper.new.main
  rescue Exception => e
    report(to: 'Muhammad Adeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end  
end
