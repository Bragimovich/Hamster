# frozen_string_literal: true

require_relative '../lib/ak_lawyer_scraper'
require_relative '../lib/ak_lawyer_parser'
require_relative '../lib/ak_lawyer_database'
require_relative '../lib/ak_lawyer_runs'

require_relative '../models/alaska_db_model'

def scrape(options)
  if @arguments[:update]
    Scraper.new(1)
  else
    Scraper.new()
  end
end
