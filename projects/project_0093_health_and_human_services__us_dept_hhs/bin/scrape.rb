# frozen_string_literal: true
require_relative '../lib/hhs_scraper'
require_relative '../models/us_dept_hhs'

def scrape(options)
  year = Date.today.year
  update = 1
  if @arguments[:year]
    begin
      year = @arguments[:year].to_i
    rescue
      year = 0
    end
  elsif @arguments[:update] | @arguments[:parse] | @arguments[:store]
    year = Date.today.year
  elsif @arguments[:download]
    update = 0
  end
  q = Scraper.new(year, update)
end
