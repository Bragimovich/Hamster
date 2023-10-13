# frozen_string_literal: true

require_relative '../lib/dol_scraper'

def scrape(options)
  begin
    DolScraper.new.main
  rescue Exception => e
    report(to: 'Muhammad Adeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end  
end
