# frozen_string_literal: true
require_relative '../lib/scraper'

def scrape(options)
  scraper = Scrape.new
  scraper.download
  scraper.parse_file
  report(to: 'Yunus Ganiyev', message: 'Scrapping `project_0531_cms_gov_covid-19_vaccine_rates_v2` done!')
rescue => e
  puts e.full_message
end
