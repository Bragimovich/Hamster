# frozen_string_literal: true

require_relative '../lib/ks_ac_case_scraper'
require_relative '../lib/ks_ac_case_parser'

def scrape(options)

  scraper = KsAcCaseScraper.new
  parser = KsAcCaseParser.new

  if options[:download]
    scraper.start
  elsif options[:store]
    parser.start
  elsif options[:auto]
    scraper.start
    p '........................................ went to sleep for 5 sec ........................................'
    sleep 5
    parser.start
  elsif options[:update]
    scraper.start(update: true)
    p '........................................ went to sleep for 5 sec ........................................'
    sleep 5
    parser.start(update: true)
  else
    puts "No valid parameters supplied. Use --download/store/auto/update. Finishing..."
  end

rescue => e
  puts e, e.full_message
  Hamster.report message: "project_0390 scrape.rb:\n#{e.inspect}", to: 'U031HSK8TGF'
end
