# frozen_string_literal: true

require_relative 'lib/pima_tax_parser'
require_relative 'lib/pima_tax_scraper'
require_relative 'lib/pima_tax_put_in_db'
require_relative 'models/zipcode_data'
require_relative 'models/pima_tax_table'
require_relative 'models/pima_tax_runs_table'

def scrape(options)
  scraper = PimaTaxScraper.new
  
  if options[:download]
    scraper.gathering
  elsif options[:store]
    scraper.storing
  elsif options[:fix]
    scraper.fix
  elsif options[:update]
    scraper.gathering
    scraper.storing
  end
end
