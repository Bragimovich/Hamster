
require_relative '../lib/tax_ex_scraper'
require_relative '../lib/tax_ex_downloader'
require_relative '../lib/tax_exp_database'
require_relative '../lib/tax_exp_runs'
require_relative '../models/tax_exp_db_model'


require 'zip'

def scrape(options)
  if options[:download]
    if options[:update]
      Scraper.new(1)
    else
      Scraper.new()
    end
  end
end