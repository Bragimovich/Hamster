# frozen_string_literal: true

require_relative '../lib/doe_scraper'
require_relative '../lib/doe_parser'
require_relative '../lib/doe_database'

require_relative '../models/us_dept_education'


def scrape(options)
  if @arguments[:update]
    Scraper.new(1)
  else
    Scraper.new()
  end
end
