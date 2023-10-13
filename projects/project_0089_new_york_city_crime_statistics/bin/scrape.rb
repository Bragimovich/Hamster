# frozen_string_literal: true
# 
require_relative '../lib/ny_crime_stat_scraper'
require_relative '../lib/ny_crime_stat_parser'

def scrape(options)
  scraper = NYCrimeStatScraper.new
  parser = NYCrimeStatParser.new
  begin
    if options[:download]
      scraper.download
    elsif options[:store]
      parser.store
    end
  rescue StandardError => e
    report(to: 'U03CPDD648Y', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
