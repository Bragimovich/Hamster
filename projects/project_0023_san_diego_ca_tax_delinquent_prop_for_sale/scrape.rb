# frozen_string_literal: true
require_relative 'lib/scraper'
require_relative 'lib/parser'

def scrape(options)
  scraper = Scraper.new
  scraper.download if options[:download]
  scraper.store if options[:store]
  report(to: 'Yunus Ganiyev', message: 'Scrapping done!')
end

