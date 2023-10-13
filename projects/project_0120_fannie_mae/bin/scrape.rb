# frozen_string_literal: true

require_relative '../lib/fannie_mae'

def scrape(options)
  scraper = FannieMaeScrape.new
  scraper.main
end
