# frozen_string_literal: true

require_relative '../lib/il_scraper'
require_relative '../lib/il_parser'
require_relative '../lib/il_database'


require_relative '../models/illinois_by_location'
require_relative '../models/illinois_tax_type_totals'

def scrape(options)
  if @arguments[:store]
    Scraper.new(store:1)
  elsif @arguments[:update]
    Scraper.new(update:1)
  else
    Scraper.new(download:1)
  end
end
