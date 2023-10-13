# frozen_string_literal: true
require_relative '../lib/scraper'

def scrape(options)
  begin
    scraper = Scraper.new
    scraper.main
  rescue StandardError => e
    puts "#{e} | #{e.backtrace}"
  end
end