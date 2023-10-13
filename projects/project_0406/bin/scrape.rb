# frozen_string_literal: true

require_relative '../lib/ok_ac_case_scraper'
require_relative '../lib/ok_ac_case_parser'

def scrape(options)

  scraper = OkAcCaseScraper.new
  parser = OkAcCaseParser.new

  if options[:download]
    scraper.start
  elsif options[:store]
    parser.start
  elsif options[:update]
    parser.start(true)
  # elsif options[:bind]
  #   parser.bind
  end

end
