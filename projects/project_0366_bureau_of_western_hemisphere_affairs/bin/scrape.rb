# frozen_string_literal: true
require_relative '../lib/scraper'

def scrape(options)
  begin
    obj = ScraperClass.new
    obj.download
  rescue Exception => e
    Hamster.logger.error("Error: #{e.full_message}")
    Hamster.report(to: 'UK50M4K3R', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nDownload error:\n#{e.full_message}", use: :slack)
  end
end
