# frozen_string_literal: true
require_relative '../lib/scraper'
require_relative '../lib/store'
require_relative '../models/illinois'
require_relative '../models/illinois_runs'
require_relative '../models/illinois_tmp'
require_relative '../lib/last30_days'
require_relative '../lib/abstract_scraper.rb'
require_relative '../lib/update_last_year'
require_relative '../lib/parser.rb'
require_relative '../lib/update_source_url'

def download_start
  Illinois_runs.create if Illinois_runs.all.empty?

  id_max = Illinois_runs.all.maximum(:id)
  status = Illinois_runs.find(id_max).status

  if (status === "finish")
    illinois_id = Illinois_runs.create.id
    status = Illinois_runs.find(illinois_id).status
  else
    illinois_id = id_max
  end

  status = Illinois_runs.find(illinois_id).status

  if status === 'processing'
    runs = Illinois_runs.find(illinois_id)
    runs.status = 'lists_start'
    runs.save

    @run_id = runs.id
    Scraper.new.download

    runs.status = 'lists_ok'
    runs.save
  end

  status = Illinois_runs.find(illinois_id).status

  if status === 'lists_ok'
    runs = Illinois_runs.find(illinois_id)
    runs.status = 'lists_save_start'
    runs.save

    @run_id = runs.id
    Scraper.new(@run_id).get_letter_ids

    runs = Illinois_runs.find(illinois_id)
    runs.status = 'lists_save_ok'
    runs.save
  end

  status = Illinois_runs.find(illinois_id).status

  if status === 'lists_save_ok'
    runs = Illinois_runs.find(illinois_id)
    runs.status = 'lawyers_desc_start'
    runs.save

    Scraper.new(illinois_id).download_description

    runs = Illinois_runs.find(illinois_id)
    runs.status = 'lawyers_desc_ok'
    runs.save
  end

  status = Illinois_runs.find(illinois_id).status

  if status === 'lawyers_desc_ok'
    runs = Illinois_runs.find(illinois_id)
    runs.status = 'store_start'
    runs.save

    Store.new(illinois_id).parse

    runs = Illinois_runs.find(illinois_id)
    runs.status = 'finish'
    runs.save
  end

end

def download_description
  @run_id = Illinois_runs.maximum(:id)
  Scraper.new(@run_id).download_description
  run = Illinois_runs.find(@run_id)
  run.status = 'lawyers_ok'
  run.save
end

def download
  unless Illinois_runs.exists?(status: 'lists_ok')
    runs = Illinois_runs.new
    @run_id = runs.id
    Scraper.new(@run_id).download
    runs.status = 'lists_ok'
    runs.save
  end

  if Illinois_runs.exists?(status: 'lists_ok')
    runs = Illinois_runs.find_by(status: 'lists_ok')
    @run_id = runs.id
    Scraper.new.download_layers
    runs.status = 'lawyers_ok'
    runs.save
  end

end

def download_last30day
  Illinois_runs.create
  status = run.status

  if status == "finish"
    runs = Illinois_runs.new
    runs.save
    Last30Days.new(runs.id).download
    runs.status = 'lists_ok'
    runs.save
  end

  if Illinois_runs.exists?(status: 'lists_ok')
    runs = Illinois_runs.find_by(status: 'lists_ok')
    @run_id = runs.id
    Scraper.new(@run_id).download_description
    runs.status = 'lawyers_ok'
    runs.save
  end
  store
  move_to_main_table
  # runs = Illinois_runs.find_by(status: 'lists_ok')
  # @run_id = runs.id
  # Scraper.new(@run_id).get_letter_ids
end

def move_to_main_table
  if Illinois_runs.exists?(status: 'store_ok')
    runs = Illinois_runs.find_by(status: 'store_ok')
    @run_id = runs.id
    Last30Days.new(@run_id).move_to_main_table
    runs.status = 'finish'
    runs.save
  end
end

def store
  if Illinois_runs.exists?(status: 'lawyers_ok')
    runs = Illinois_runs.find_by(status: 'lawyers_ok')
    @run_id = runs.id
    Store.new(@run_id).parse
    runs.status = 'store_ok'
    runs.save
  end
end

def download_last_year(options)
  if Illinois_runs.last.status == "finish"
    runs = Illinois_runs.new
    runs.status = 'process_upd_years'
    runs.save
    options["run_id"] = runs.id
  else
    runs = Illinois_runs.last
    options["run_id"] = runs.id
  end
  UpdateLastYear.new(options)
end

def scrape(options)
  if options[:download_lists]
    download_lists
  elsif options[:download_description]
    download_description
  elsif options[:download]
    download_last30day
  elsif options[:store]
    store
  elsif options[:auto]
    download_start
    # elsif options[:update]
    #   download_last30day
    #   download_description
    #   store
  elsif options[:update]
    download_last30day

  elsif options[:update_last_year]
    download_last_year options
  elsif options[:update_source_url]
    links = UpdateSourceUrl.new(options)
    links.update
  end
end
