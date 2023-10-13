# frozen_string_literal: true

require_relative '../lib/maine_bar_scraper'
require_relative '../lib/maine_bar_parser'

def scrape(options)

  scraper = MaineBarScraper.new
  parser = MaineBarParser.new

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
    p 'No proper parameters specified. Try again.'
  end

rescue StandardError => e
  puts e.inspect, e.full_message
  Hamster.report(to: 'U031HSK8TGF', message: "project_0391 error in store.rb:\n#{e.inspect}")
end