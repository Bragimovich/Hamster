# frozen_string_literal: true

require_relative '../lib/cisa_database'
require_relative '../lib/cisa_parser'
require_relative '../lib/cisa_scraper'
require_relative '../models/us_dept_coti_model'


def scrape(options)

  if @arguments[:parse] | @arguments[:store]
    Scraper.new(update=0)
  elsif @arguments[:update]
    Scraper.new(update=1)
  else
    Scraper.new(update=0)
  end
end
