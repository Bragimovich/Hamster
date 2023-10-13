# frozen_string_literal: true
require_relative '../lib/scraper'
require_relative '../lib/store'
require_relative '../models/us_epa'
def scrape(options)
  if options[:download]
    Scraper.new.download
  elsif options[:download_2019_2015]
    Scraper.new.download_2019_2015
  elsif  options[:download_2014_1994]
    Scraper.new.download_2014_1994
  elsif options[:store]
    max_run = UsEpa.maximum("touched_run_id")
    if max_run.nil?
      run_id = 1
    else
      run_id = max_run.to_i + 1
    end
    Store.new(run_id).parse(2021)

  elsif options[:update]

    Scraper.new.download
    max_run = UsEpa.maximum("touched_run_id")
    if max_run.nil?
      run_id = 1
    else
      run_id = max_run.to_i + 1
    end
    Store.new(run_id).parse(2021)

  elsif options[:store_2014_1994]
    max_run = UsEpa.maximum("touched_run_id")
    if max_run.nil?
      run_id = 1
    else
      run_id = max_run.to_i + 1
    end
    Store.new(run_id).parse_2014_1994
  elsif options[:store_2019_2015]
    max_run = UsEpa.maximum("touched_run_id")
    if max_run.nil?
      run_id = 1
    else
      run_id = max_run.to_i + 1
    end
    Store.new(run_id).parse_2019_2015
  elsif options[:auto]
    Scraper.new.download
    Scraper.new.download_2019_2015
    Scraper.new.download_2014_1994
    max_run = UsEpa.maximum("touched_run_id")
    if max_run.nil?
      run_id = 1
    else
      run_id = max_run.to_i + 1
    end
    Scraper.new.download_environment
           .parse_2014_1994
           .parse_2019_2015
  elsif options[:bug_environment]
    Scraper.new.download_environment
  end
end
