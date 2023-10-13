# frozen_string_literal: true
require_relative '../lib/nrc_scraper'
require_relative '../lib/nrc_parser'
require_relative '../lib/nrc_database'
require_relative '../models/us_dept_nrc'

def scrape(options)
  year = Date.today().year
  counts = 10
  job ='g'
  if @arguments[:test]
    delete_null_rows
    return
  end

  if @arguments[:date]
    run_for_all_years(start_year=2016, job='date', counts=0)
    return
  end

  if @arguments[:update]
    Scraper.new(year, 'g', 0)
    Scraper.new(year, 's', 0)
    return 0
  end

  if @arguments[:c]
    begin
      counts = @arguments[:c].to_i
    end
  end
  if @arguments[:year]
    begin
      year = @arguments[:year].to_i
    rescue
      year = 0
    end
  elsif @arguments[:parse] | @arguments[:store]
    year = 2022
  end
  job = @arguments[:job] if @arguments[:job]
  if @arguments[:all]
    run_for_all_years(year, job, counts)
  else
    q = Scraper.new(year)
  end

end
