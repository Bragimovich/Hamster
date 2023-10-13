# frozen_string_literal: true

require_relative 'lib/refugee_parser'
require_relative 'lib/refugee_scraper'
require_relative 'models/rpc_refugee_arrivals_by_admission_category'
require_relative 'models/rpc_refugee_arrivals_by_admission_category_run'

def scrape(options)
  scraper = RefugeeScraper.new
  
  if options[:download]
    scraper.download
  end
  
  if options[:store]
    scraper.store
  end
end
