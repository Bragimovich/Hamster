# frozen_string_literal: true
# 
require_relative '../lib/prison_scraper'

def scrape(options)
  PrisonScraper.new.start
end
