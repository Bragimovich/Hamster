# frozen_string_literal: true

require_relative '../lib/weather_scraper'
require_relative '../lib/weather_keeper'
require_relative '../lib/weather_parser'

require_relative '../models/weather_history'

def scrape(options)
  Scraper.new(**options)
end
