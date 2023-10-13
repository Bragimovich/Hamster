# frozen_string_literal: true
require_relative 'lib/scraper'
require_relative 'lib/parser'

def scrape(options)
  p 111111111111111111111111
  scraper = Scraper.new
  scraper.download_xlsx if options[:download]
  # scraper.download if options[:download]
  report(to: 'Yunus Ganiyev', message: 'Scrapping done!')
end
