# frozen_string_literal: true

require_relative '../lib/oversight_scraper.rb'

def scrape(options)
  begin
    OversightScraper.new.main
  rescue Exception => e
    Hamster.report(to: 'Muhammad Adeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
