# frozen_string_literal: true

require_relative '../lib/parole_scraper'

def scrape(options)
  ParoleScraper.new.start
end
