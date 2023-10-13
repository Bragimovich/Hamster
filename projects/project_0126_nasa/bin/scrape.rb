# frozen_string_literal: true

require_relative '../lib/nasa_scraper.rb'

def scrape(options)
  begin
    mian_class_obj = NasaScrape.new
    mian_class_obj.main
  rescue Exception => e
    report(to: 'Aqeel Anwar', message: "Project # 126:\n#{e.full_message}", use: :slack)
  end
end
