# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/store'
require_relative '../lib/parser'

def scrape(options)
  begin
    if options[:download]
      Scraper.new.scraper
    elsif options[:store]
      Store.new.store
    elsif options[:parse]
      Parser.new.parser
    end
  rescue Exception => e
    report(to: 'Aqeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end  
end
