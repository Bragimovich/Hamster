# frozen_string_literal: true

require_relative 'lib/scraper'

def scrape(options)
  scraper = Scraper.new
  scraper.download
  scraper.parse_file
rescue => e
  puts e, e.full_message
  report(to: 'Yunus Ganiyev', message: 'Scrapping `#80 mm_new_residential_construction` done!')
end
