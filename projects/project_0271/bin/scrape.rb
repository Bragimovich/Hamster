# frozen_string_literal: true

require_relative '../lib/us_dept_ways_and_means_scraper'

def scrape(options)

  scraper = UsDeptWaysAndMeansScraper.new

  scraper.start

end