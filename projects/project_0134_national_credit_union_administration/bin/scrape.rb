# frozen_string_literal: true

require_relative '../lib/us_ncua_scraper.rb'

def scrape(options)
  begin
    if options[:scraper]
      Scraper.new.main
    elsif options[:categories]
      Scraper.new.insert_categories
    end
  rescue Exception => e
    report(to: 'UK50M4K3R', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
