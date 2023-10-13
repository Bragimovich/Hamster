# frozen_string_literal: true
require_relative '../lib/scraper'
require_relative '../lib/parser'

def scrape(options)
  begin
    if options[:download]
      Scraper.new.download
    elsif options[:store]
      Scraper.new.store 
    end
  rescue Exception => e
    Hamster.report(to: 'Aqeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
