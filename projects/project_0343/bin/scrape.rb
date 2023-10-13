# frozen_string_literal: true

require_relative '../lib/boiesa_scraper'

def scrape(options)
  obj = BoiesaScraper.new
  obj.download
  obj.scrape
end
