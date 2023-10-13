# frozen_string_literal: true

require_relative '../lib/scraper.rb'

def scrape(options)
  begin
    if options[:scraper]
      Scraper.new.store
    elsif options[:parser]
      Scraper.new.parser
    end
  rescue Exception => e
   report(to: 'Muhammad Adeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end  
end
