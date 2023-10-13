# frozen_string_literal: true

require_relative '../lib/scoenr_scraper'
require_relative '../lib/scoenr_database'
require_relative '../lib/scoenr_parser'
require_relative '../models/us_dept_scoenr_model'


def scrape(options)
  type = @arguments[:type]

  if @arguments[:parse] | @arguments[:store]
    Scraper.new(update=0, :d)
    Scraper.new(update=0, :r)
  elsif @arguments[:update]
    Scraper.new(update=1, :d)#, type)
    Scraper.new(update=1, :r)
  else
    Scraper.new(update=0, type)
  end
end
