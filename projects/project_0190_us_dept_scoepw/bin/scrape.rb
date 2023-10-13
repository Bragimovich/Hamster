# frozen_string_literal: true

require_relative '../lib/scoepw_database'
require_relative '../lib/scoepw_parser'
require_relative '../lib/scoepw_scraper'
require_relative '../models/us_dept_scoepw_model'


def scrape(options)
  type = @arguments[:type]

  if @arguments[:parse] | @arguments[:store]
    Scraper.new(update=0, type)
  elsif @arguments[:update]
    Scraper.new(update=1, :news)#, type)
    Scraper.new(update=1, :pr)
  else
    Scraper.new(update=0, type)
  end
end
