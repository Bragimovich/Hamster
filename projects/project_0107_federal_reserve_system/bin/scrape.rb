# frozen_string_literal: true

require_relative '../lib/frs_parser'
require_relative '../lib/frs_scraper'
OLEKSII_KUTS = 'U03F2H0PB2T'
STARS = "\n#{'*'*77}"

def clear_log
  File.open(logger.instance_variable_get(:@logdev).filename, 'w') {}
end

def scrape(options)
  clear_log if options[:clear_log]

  scraper = FRSScraper.new
  parser = FRSParser.new

  scraper.start if options[:download] || options[:auto]
  parser.start if options[:store] || options[:auto]
end
