# frozen_string_literal: true

require_relative '../lib/fl_lawyer_scraper'
require_relative '../lib/fl_lawyer_parser'
require_relative '../lib/fl_lawyer_database'
require_relative '../lib/fl_lawyer_runs'

require_relative '../models/florida_db_model'

def scrape(options)
  if @arguments[:update]
    Scraper.new(1, continue: @arguments[:continue])
  else
    Scraper.new()
  end
end
