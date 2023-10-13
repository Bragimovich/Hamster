# frozen_string_literal: true

require_relative '../lib/scraper'

def scrape(options)
  obj = ScraperClass.new
  obj.download
  obj.scrape
end
