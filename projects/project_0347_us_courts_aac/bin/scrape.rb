# frozen_string_literal: true

require_relative '../lib/ak_saac_case_scraper'
require_relative '../lib/ak_saac_case_parser'

def scrape(options)

  scraper = AkSaacCaseScraper.new
  parser = AkSaacCaseParser.new

  if options[:download]
    scraper.start
  elsif options[:store]
    parser.start
  elsif options[:auto]
    scraper.start
    p 'went to sleep for 5 sec ...'
    sleep 5
    parser.start
  elsif options[:update]
    scraper.start(update: true)
    p 'went to sleep for 5 sec ...'
    sleep 5
    parser.start(update: true)
  else
    p 'No parameters specified. Try again.'
  end

rescue StandardError => e
  puts e, e.full_message
  Hamster.report(to: 'U031HSK8TGF', message: "project_0347 error in scrape.rb:\n#{e}")
end
