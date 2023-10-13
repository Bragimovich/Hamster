# frozen_string_literal: true

require_relative '../lib/peace_corps_scraper'

def scrape(options)
  begin 
    PeaceCorpsScraper.new.scraper
  rescue Exception => e
   Hamster.report(to: 'Muhammad Adeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
