# frozen_string_literal: true

require_relative '../lib/scraper'

def scrape(options)
  begin
    if options[:download]
      Scraper.new.download
    elsif options[:store]
      Scraper.new.parse
    end
  rescue Exception => e
    report(to: 'Muhammad Adeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
