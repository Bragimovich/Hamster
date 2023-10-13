# frozen_string_literal: true

require_relative '../lib/fl_saac_manager'
require_relative '../lib/fl_saac_scraper'
require_relative '../lib/fl_saac_parser'
require_relative '../lib/fl_saac_keeper'

require_relative '../models/fl_saac'

def scrape(options)
  ManagerFLSAAC.new(**options)
end

