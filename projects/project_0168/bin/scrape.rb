# frozen_string_literal: true

require_relative '../lib/scraper'

def scrape(options)
  begin
    script = USPostalServiceScraper.new
    if options[:download]
      script.download_data
    elsif options[:store]
      script.store_data
    else
      script.download_data
      script.store_data
    end
    return 0
  rescue StandardError => e
    puts "#{e} | #{e.backtrace}"
  end
end