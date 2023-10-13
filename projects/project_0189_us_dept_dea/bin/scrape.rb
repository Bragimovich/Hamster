# frozen_string_literal: true

require_relative '../lib/dea_scraper'
require_relative '../lib/dea_parser'
require_relative '../lib/dea_database'
require_relative '../models/us_dept_dea_model'


def scrape(options)
  year = 2021
  if @arguments[:parse] | @arguments[:store]
    Scraper.new(update=0)
  elsif @arguments[:update]
    Scraper.new(update=1)
  else
    Scraper.new(update=0)
  end
end
