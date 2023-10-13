# frozen_string_literal: true
require_relative '../lib/scraper'

def scrape(options)
  begin
    script = Scraper.new
    script.main
  rescue StandardError => e
    puts "#{e} | #{e.backtrace}"
  end
end
