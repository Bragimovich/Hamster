# frozen_string_literal: true

require_relative '../lib/ny_scraper'
require_relative '../lib/ny_parser'
require_relative '../lib/ny_database'
require_relative '../lib/all_courts'
require_relative '../lib/document_list_new'
require_relative '../lib/case_detail_new'


require_relative '../models/ny_cases'

# require_relative '../lib/il_database'
#
#
# require_relative '../models/illinois_by_location'
# require_relative '../models/illinois_tax_type_totals'

def scrape(options)

  if @arguments[:old_amount]
    Scraper.new(**@arguments)
  elsif @arguments[:browser]
    Scraper.new(browser:1)
  elsif @arguments[:update]
    Scraper.new(**@arguments)
  elsif @arguments[:check]
    Scraper.new(check:1)
  else
    Scraper.new(store:1)
  end
end
