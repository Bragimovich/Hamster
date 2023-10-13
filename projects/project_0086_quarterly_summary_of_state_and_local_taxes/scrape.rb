# frozen_string_literal: true
require_relative 'lib/scraper'

def scrape(options)
  scraper = Scraper.new
  scraper.download
  scraper.parse_file
rescue => e
  puts e, e.full_message
  report(to: 'Yunus Ganiyev', message: 'Scrapping `#86 quarterly_summary_of_state_and_local_taxes` done!')
end
