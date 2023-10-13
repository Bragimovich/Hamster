# frozen_string_literal: true

require_relative '../lib/scraper'
LOGFILE = "scarepe_log_file.log"

def scrape(options)
  obj = ScraperClass.new
  obj.download
  obj.scrape 
end
