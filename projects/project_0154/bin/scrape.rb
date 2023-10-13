# frozen_string_literal: true

require_relative '../lib/nm_lawyer_status_scraper'
require_relative '../lib/nm_lawyer_status_parser'

def scrape(options)

  scraper = NMLawyerStatusScraper.new
  parser = NMLawyerStatusParser.new

  if options[:download]
    scraper.start
  elsif options[:store]
    parser.start
  elsif options[:auto]
    scraper.start
    p 'went to sleep for 5 sec ...'
    sleep 5
    parser.start
  else
    puts "No valid parameters supplied. Use --download/store/auto. Finishing..."
  end

rescue => e
  puts e, e.full_message
  Hamster.report(to: 'Alim Lumanov', message: "Project #154 scrape.rb:\n#{e}")
end
