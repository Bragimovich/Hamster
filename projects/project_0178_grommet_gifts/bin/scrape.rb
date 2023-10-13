# frozen_string_literal: true

require_relative '../lib/ggifts_scraper'
require_relative '../lib/ggifts_parser'
require_relative '../lib/ggifts_database'
require_relative '../lib/ggifts_match'


require_relative '../models/grommet_gifts_model'


def scrape(options)

  if @arguments[:download]
    Scraper.new(download:1)
  elsif @arguments[:match]
    Match.new()
  elsif @arguments[:categories]
    Scraper.new(categories:1)
  else
    Scraper.new()
  end
end
