# frozen_string_literal: true

# hamster --grab=183 --store
# hamster --grab=183 --store_archive
# hamster --grab=183 --download
# hamster --grab=183 --download_archive

require_relative '../lib/nifa_parser'
require_relative '../lib/nifa_scraper'

def scrape(options)
  scraper = NIFAScraper.new
  parser = NIFAParser.new

  if options[:download]
    scraper.start_download
  elsif options[:store]
    scraper.start_store
  elsif options[:download_archive]
    scraper_archive.start_download
  elsif options[:store_archive]
    scraper_archive.start_store
  end
end