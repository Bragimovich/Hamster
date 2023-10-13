# frozen_string_literal: true

require_relative '../lib/omctp_scraper'

def scrape(options)
  begin
    if options[:download]
      OmctpScraper.new.download
    elsif options[:store]
      OmctpScraper.new.scrape
    end
  rescue Exception => e
    report(to: 'Aqeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
