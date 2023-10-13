# frozen_string_literal: true

require_relative '../lib/blm_database'
require_relative '../lib/blm_parser'
require_relative '../lib/blm_scraper'
require_relative '../models/us_dept_blm_model'


def scrape(options)

  if @arguments[:parse] | @arguments[:store]
    Scraper.new(update=0)
  elsif @arguments[:update]
    Scraper.new(update=1)
  else
    Scraper.new(update=0)
  end
end
