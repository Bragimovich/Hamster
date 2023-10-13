# frozen_string_literal: true

require_relative '../lib/nist_scraper.rb'

def scrape(options)
  begin
    NISTScraper.new.main
  rescue Exception => e
    report(to: 'Muhammad Adeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
