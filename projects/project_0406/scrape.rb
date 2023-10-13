# frozen_string_literal: true

require_relative 'lib/ok_ac_case_scraper'
require_relative 'lib/ok_ac_case_parser'

def scrape(options)

  scraper = OkAcCaseScraper.new
  parser = OkAcCaseParser.new

  if options[:download]
    scraper.start(false)
  elsif options[:store]
    parser.start(false)
  elsif options[:update]
    scraper.start(true)
    sleep 60
    parser.start(true)
  end

end

