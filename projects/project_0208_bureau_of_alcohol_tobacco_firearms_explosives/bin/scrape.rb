# frozen_string_literal: true

require_relative '../lib/baltfe'

def scrape(options)
  begin
    Scraper.new.press_release_scraper
  rescue Exception => e
    report(to: 'Aqeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
