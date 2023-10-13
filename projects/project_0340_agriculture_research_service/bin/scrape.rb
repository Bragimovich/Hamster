# frozen_string_literal: true
require_relative '../lib/ag_parser'
require_relative '../lib/ag_scraper'

def scrape(options)
  AGScraper.new.download
  AGScraper.new.scrape
end
