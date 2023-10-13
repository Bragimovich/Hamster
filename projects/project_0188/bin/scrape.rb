require_relative '../lib/edlabor_house_scraper'
require_relative '../lib/edlabor_house_parser'

def scrape(options)
  scraper = EdlaborHouseScraper.new
  parser  = EdlaborHouseParser.new

  if options[:download]
    scraper.start
  elsif options[:store]
    parser.start
  end
end
