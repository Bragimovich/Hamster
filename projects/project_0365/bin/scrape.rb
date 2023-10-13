# frozen_string_literal: true

require_relative '../lib/scraper'

def scrape(options)
  begin
    obj = ScraperClass.new
    obj.download
    obj.scrape
  rescue StandardError => e
    Hamster.logger.error("Error: #{e.full_message}")
    report(to: 'UD1LWNPEW', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
