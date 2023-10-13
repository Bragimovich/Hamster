# frozen_string_literal: true

require_relative '../lib/hscr_database'
require_relative '../lib/hscr_parser'
require_relative '../lib/hscr_scraper'
require_relative '../models/us_dept_hscr_model'


def scrape(options)
  type = @arguments[:type]

  if @arguments[:parse] | @arguments[:store]
    Scraper.new(update=0)
  elsif @arguments[:update]
    Scraper.new(update=1)
  else
    Scraper.new(update=0)
  end
end
