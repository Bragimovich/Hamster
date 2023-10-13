# frozen_string_literal: true

require_relative '../lib/scraper'

def scrape(options)
  if options[:download]
    ScraperClass.new.download
  elsif options[:scrape]
    ScraperClass.new.scrape
  end
end
