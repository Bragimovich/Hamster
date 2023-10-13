# frozen_string_literal: true
require_relative '../lib/scraper'

def scrape(options)
  if @arguments[:date]
    year, month, day = @arguments[:date].split('-')
  end
  if @arguments[:download]
    year, month, day = @arguments[:download].split('-')
    Scraper.new(year.to_i, month.to_i, day.to_i)
  elsif @arguments[:update]
    unless year
      d = Date.today()
      year, month, day = d.year, d.month, d.day
    end
    Scraper.new(year.to_i, month.to_i, day, @arguments[:update])
  elsif @arguments[:old]
    #get_from_old
  else
    Scraper.new()
  end

end
