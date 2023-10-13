# frozen_string_literal: true
require_relative '../lib/scraper'
require_relative '../lib/store'
require_relative '../models/us_dhs'
def scrape(options)
  if options[:download]
    Scraper.new.download
  elsif options[:download_old]
    Scraper.new.download_archive
  elsif options[:store]
    max_run = UsDhs.maximum("touched_run_id")
    if max_run.nil?
      run_id = 1
    else
      run_id = max_run.to_i + 1
    end
    Store.new(run_id).parse
  elsif options[:store_old]
    max_run = UsDhs.maximum("touched_run_id")
    if max_run.nil?
      run_id = 1
    else
      run_id = max_run.to_i + 1
    end
    Store.new(run_id).parse_old
  elsif options[:auto]
    Scraper.new.download
    max_run = UsDhs.maximum("touched_run_id")
    if max_run.nil?
      run_id = 1
    else
      run_id = max_run.to_i + 1
    end
    Store.new(run_id).parse
  end
end
